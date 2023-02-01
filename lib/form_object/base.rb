# frozen_string_literal: true

require 'active_model'
require 'multi_model_wizard/dynamic_validation'

module FormObject
  class AttributeNameError < StandardError; end
  class Base
    include MultiModelWizard::DynamicValidation
    include ActiveModel::Model
    include ActiveModel::AttributeAssignment

    class << self
      # Creates a new instance of the form object with all models and configuration
      # @note This is how all forms should be instantiated
      # @param block [Block] this yields to a block with an instance of its self
      # @return form object [FormObjects::Base]
      def create_form
        instance = new
        yield(instance)
        instance.send(:init_attributes)
        instance
      end

      # Needs to be overridden by child class.
      # @note This method needs to be overridden with an array of symbols
      # @return array [Array]
      def form_steps
        raise NotImplementedError
      end
    end

    # These are the default atrributes for all form objects
    ATTRIBUTES = %i[
      current_step
      new_form
    ]

    attr_reader :extra_attributes, :models, :dynamic_models, :multiple_instance_models

    # WARNING: Light meta programming
    # We will create an attr_accessor for all atributes
    # @note This ATTRIBUTES can be overriden in child classes
    ATTRIBUTES.each { |attribute| attr_accessor attribute }

    alias new_form? new_form 

    def initialize
      @models = []
      @dynamic_models = []
      @multiple_instance_models = []
      @extra_attributes = []
      @new_form = true
    end

    # Checks if the form and its attributes are valid
    # @note This method is here because the Wicked gem automagically runs this methdo to move to the next step
    # @note This method needs return a boolean after attempting to create the records 
    # @return boolean [Boolean]
    def save
      valid?
    end

    # Add a custom error message and makes the object invalid
    #
    def invalidate!(error_msg = nil)
      errors.add(:associated_model, error_msg) unless error_msg.nil?
      errors.add(:associated_model, 'could not be properly save')
    end

    # Boolean method returns if the object is on the first step or not
    # @return boolean [Boolean]
    def first_step?
      return false if current_step.nil?
      return true unless current_step.to_sym

      form_steps.first == current_step.to_sym
    end

    # Gets all of the form objects present attributes and returns them in a hash
    # @note This method will only return a key value pair for attributes that are not nil
    # @note It ignores the models arrays, errors, etc. 
    # @return hash [ActiveSupport::HashWithIndifferentAccess]
    def attributes
      hash = ActiveSupport::HashWithIndifferentAccess.new
      instance_variables.each_with_object(hash) do |attribute, object|
        next if %i[@errors @validation_context 
                  @models @dynamic_models
                  @multiple_instance_models
                  @extra_attributes].include?(attribute)

        key = attribute.to_s.gsub('@','').to_sym
        object[key] = self.instance_variable_get(attribute)
      end
    end

    # Returns an list of all attribute names as symbols 
    # @return array [Array] of symbol attribute names
    def attribute_keys
      ATTRIBUTES
    end

    # Returns all of the attributes for a model
    # @note If you dont pass a model to extra attributes they will not show up here
    # @note attributes for model does not work for multiple_instance_models
    # @param model class [ActiveRecord]
    # @return hash [Hash]
    def attributes_for(model)
      model_is_activerecord?(model)

      hash = ActiveSupport::HashWithIndifferentAccess.new
      
      attribute_lookup.each_with_object(hash) do |value, object|
        lookup = value[1]
        form_attribute = value[0]
        object[lookup[:original_method]] = attributes[form_attribute] if lookup[:model] == model.name
      end
    end

    # Takes a hash of key value pairs and assigns those attributes values to its
    # corresponding methods/instance variables
    # @note If you give it a key that is not a defined method of the class it will simply move on to the next
    # @param hash [Hash]
    # @return self [FormObject] the return value is the instance of the form object with its updated values
    def set_attributes(attributes_hash)
      attributes_hash.each do |pair|
        key = "#{pair[0].to_s}="
        value = pair[1]
        self.send(key, value)
      rescue NoMethodError
        next 
      end
      self
    end


    # Given n number of atrribute names this method will iterate over each attribute and validate that attribute
    # using the model that the attribute orignated from to validate it
    # @note this method uses a special method #validate_attribute_with_message this method comes from
    # the an DynamicValidation module and is not built in with ActiveRecord
    # @note this method will add the model errors to your object instance and invalidate it. 
    # The model errors are using the original attribute names
    # @param symbol names of instance methods [Symbol]
    # @return boolean [Boolean] this method will return true if all attributes are valid and false if not
    def validate_attributes(*attributes)
      raise ArgumentError, 'Attributes must be a Symbol' unless attributes.all? { |x| x.is_a?(Symbol) }

      attributes.map do |single_attr|
        unless respond_to?(single_attr)
          raise FormObject::AttributeNameError, "#{single_attr.to_s} is not a valid attribute of this form object"
        end

        original_attribute = attribute_lookup.dig(single_attr.to_sym, :original_method)
        attribute_hash = { "#{original_attribute}": send(single_attr) }
        instance = attribute_lookup.dig(single_attr.to_sym, :model)&.constantize&.new
        instance&.send("#{original_attribute}=", send(single_attr))
        next if instance.nil?

        validation = validate_attribute_with_message(attribute_hash, model_instance: instance)
        if validation.valid.eql?(false)
          validation.messages.each { |err| errors.add(single_attr.to_sym, err) }
        end

        validation.valid
      end.compact.all?(true)
    end

    # Much like #validate_attributes this method will validate the attributes 
    # of a instance model using the original model
    # @note this method uses a special method #validate_attribute_with_message this method comes from
    # the an DynamicValidation module and is not built in with ActiveRecord
    # @note this method will add the model errors to your object instance and invalidate it. 
    # The model errors are using the original attribute names
    # @param symbol name of instance method [Symbol]
    # @return boolean [Boolean] this method will return true if all attributes are valid and false if not
    def validate_multiple_instance_model(attribute)
      raise ArgumentError, 'Attribute must be a Symbol' unless attribute.is_a?(Symbol)
      unless respond_to?(attribute)
        raise FormObject::AttributeNameError, "#{attribute.to_s} is not a valid attribute of this form object"
      end

      model_instance = attribute_lookup.dig(attribute.to_sym, :model)&.constantize&.new
      return nil if model_instance.nil?

      send(attribute).map do |hash_instance|
        hash_instance.map do |key, value|
          model_instance&.send("#{key}=", value)

          validation = validate_attribute_with_message({ "#{key}": value }, model_instance: model_instance )
          if validation.valid.eql?(false)
            validation.messages.each { |err| errors.add(attribute.to_sym, err) }
          end
          validation.valid
        end
      end.compact.all?(true)
    end

    # This method should be used when instantiating a new object. It is used to add extra attributes to the
    # form object that may not be accessible from the models passed in.
    # @note to have these attributes validated using the #validate_attributes method you must pass in a model
    # @note model can be an instance or the class
    # @note attributes should be an array of symbols
    # @param prefix is a string that you want to hcae in front of all your extra attributes [String]
    # @param attributes should be an array of symbols [Array]
    # @param model class or model instance  [ActiveRecord] this is the class that you want these extra attributes to be related to
    # @return array of all the extra attributes [Array]
    def add_extra_attributes(prefix: nil, attributes:, model: nil )
      if prefix.present?
        raise ArgumentError, 'Prefix must be a String' unless prefix.is_a?(String)
      end
      raise ArgumentError, 'All attributes must be Symbols' unless attributes.all? { |x| x.is_a?(Symbol) }
      model_is_activerecord?(model)

      hash = { 
              prefix: prefix || model_prefix(model), 
              attributes: attributes,
              model: model 
            } 
      extra_attributes << hash
    end

    # This method should be used when instantiating a new object. It is used to add dynamic models to the
    # form object.
    # Dynamic models are models that share a base class and are of the same family but can vary depending on child class
    # Example: A Truck model, Racecar model, and a Semi model who all have a base class of Vehicle
    # This method allows your form to recieve any of these models and keep the UI and method calls the same.
    # @note model can be an instance or the class
    # @param prefix is a string that you want to hcae in front of all your extra attributes [String]
    # @param model class or model instance  [ActiveRecord] this is the class that you want these extra attributes to be related to
    # @return array of all the dynamic models [Array]
    def add_dynamic_model(prefix:, model:)
      raise ArgumentError, 'Prefix must be a String' unless prefix.is_a?(String)
      model_is_activerecord?(model)

      @dynamic_models << { prefix: prefix, model: instance_of_model(model) }
    end

    # The add_multiple_instance_model is an instance method that is used for adding ActiveRecord models
    # multiple instance models are models that would be child models in a has_many belongs_to relationship
    # EXAMPLE: Car has_many parts
    # In this example the multiple instance would be parts because a car can have an infinte number of parts
    # @param name of the form object atrribute to retrieve these multiple instances of a model [String]
    # @param model class or instance [ActiveRecord] this is the same model that the instances should be
    # @param instances is an array of ActiveRecord models [Array] these are usually the has_many relation instances
    # @return array of all the multiple instance models models [Array]
    def add_multiple_instance_model(attribute_name: nil, model:, instances: [])
      if attribute_name.present? 
        raise ArgumentError, 'Attribute name must be a String' unless attribute_name.is_a?(String)
      end
      model_is_activerecord?(model)

      attribute_name = attribute_name || model_prefix(model, pluralize: true)
      hash = { attribute_name: attribute_name, model: instance_of_model(model), instances: instances }

      @multiple_instance_models << hash
    end

    # The add_model is an instance method that is used for adding ActiveRecord models
    # @param prefix is optional and is used to change the prefix of the models attributes [String] the prefix defaults to the model name
    # @param model class or instance [ActiveRecord] this is the same model that the instances should be
    # @return array of all the models [Array]
    def add_model(model, prefix: nil)
      if prefix.present?
        raise ArgumentError, 'Prefix must be a String' unless prefix.is_a?(String)
      end
      model_is_activerecord?(model)

      hash = { prefix: prefix || model_prefix(model), model: instance_of_model(model) }

      @models << hash
    end

    # This method is used to turn the attributes of the form into a stringified object that resembles json
    # @return form atttrubytes as a strigified hash [Hash]
    def as_json
      instance_variables.each_with_object({}) do |var, obj|
          obj[var.to_s.gsub('@','')] = instance_variable_get(var)
      end.stringify_keys
    end

    # This method is used to help validate the form object. Use required for step to do step contional validations of attributes
    # @param step is used to compare the current step [Symbol]
    # @return a true or false value if the step give is equal to or smaller in the form_steps [Boolean]
    def required_for_step?(step)
      # note: this line is specific if using the wicked gem
      return true if current_step == 'wicked_finish' || current_step.nil?

      form_steps.index(step.to_sym) <= form_steps.index(current_step.to_sym)
    end

    # Persist is used to update or create all of the models from the form object
    # @note the create method and update method that this method use will have to manually implemented by the child class
    # @note the create and update need to return a boolean based on their success or failure to udpate
    # @return the output of the create or update method [Sybmbol]
    def persist!
      new_form ? create : update
    end

    # Create all of the models from the form object and their realations
    # @note this should be done in an ActiveRecord transaction block
    # @return returns true if the transaction was successfule and false if not[Boolean]
    # EXAMPLE:
    # def create
    #   created = false
    #   begin
    #     ActiveRecord::Base.transaction do
    #       car = Car.new(attributes_for(Car))
    #       car.parts = car_parts
    #       car.save!
    #     end
    #     created = true
    #   rescue StandardError => err
    #     return created       
    #   end
    #   created
    # end
    def create
      true
    end

    # Update all of the models from the form object and their realations
    # @note this should be done in an ActiveRecord transaction block
    # @return returns true if the transaction was successfule and false if not [Boolean]
    # EXAMPLE:
    # def update
    #   updated = false
    #   begin
    #     ActiveRecord::Base.transaction do
    #       car = Car.find(car_id)
    #       car.attributes = attributes_for(Car)
    #       car.parts = car_parts
    #       car.save!
    #     end
    #     updated = true
    #   rescue StandardError => err
    #     return updated       
    #   end
    #   updated
    # end
    def update
      true
    end

    private

    # WARNING: Light meta programming
    # Used to add attributes to the ATTRIBUTES array and also create an attr_accessor for those attributes
    # This is used to add model attributes to the form object
    # @param attribute name [Symbol]
    # @return method name [Sybmbol]
    def add_attribute(attribute_name)
      ATTRIBUTES << attribute_name
      self.class.send(:attr_accessor, attribute_name)
    end

    # Used on the last step of a form wizard
    # @note this model will invalidate the form object is the persist! method does not return true
    # @return if all models were saved than true will be returned [Boolean]
    def models_persisted?
      persist! ? true : errors.add(:associated_model, 'could not be properly save')
    end

    # Returns all types of models including, dynamic models, multi instance models, etc
    # @return all models [Array]
    def all_models
      @all_models = (models + dynamic_models + multiple_instance_models).uniq
    end

    # This method is used to make sure the form object has an attr_accessor for all of the models that
    # were provided. This method is used during the initialization of a new form object instance.
    def init_attributes
      # get all model attributes and prefix them 
      all_models.each do |hash|
        prefix = hash[:prefix]
        hash[:model].attributes.keys.each do |key|
          ATTRIBUTES << "#{prefix}_#{key}".to_sym

          # set attribute history
          set_attribute_history(prefix, key, hash[:model])
        end
      end

      # add extra attributes
      init_extra_attributes

      init_multiple_instance_attributes

      # set attr_accessor
      ATTRIBUTES.uniq.each do |attribute|
        self.class.send(:attr_accessor, attribute)
      end

      # set any values from the class
      all_models.each do |hash|
        prefix = hash[:prefix] || model_prefix(hash[:model])
        hash[:model].attributes.each do |key, value|
          self.instance_variable_set("@#{prefix}_#{key}", value)
        end
      end
      @models = []
      @extra_attributes = []
    end

    # This method is used to make sure the form object has an attr_accessor for all of the multiple instance attributes 
    # This method is used during the initialization of a new form object instance.
    def init_multiple_instance_attributes
      multiple_instance_models.each do |model_hash|
        add_attribute(model_hash[:attribute_name].to_sym)
        attribute_lookup.merge!(
          "#{model_hash[:attribute_name]}": { original_method: nil, model: instance_of_model(model_hash[:model]).class.name }
        )

        instances = model_hash[:instances].map { |x| ActiveSupport::HashWithIndifferentAccess.new(x.attributes) }
        self.send("#{model_hash[:attribute_name].to_s}=", instances)
      end
    end

    # This method is used to make sure the form object has an attr_accessor for all of the extra attributes 
    # This method is used during the initialization of a new form object instance.
    def init_extra_attributes
      @extra_attribute_keys = []
      extra_attributes.each do |attr_object|
        attr_object[:attributes].each do |x|
          if attr_object[:prefix]
            ATTRIBUTES << "#{attr_object[:prefix].to_s}_#{x.to_s}".to_sym
            @extra_attribute_keys << "#{attr_object[:prefix].to_s}_#{x.to_s}".to_sym
          else
            ATTRIBUTES << x.to_sym
            @extra_attribute_keys << x.to_sym
          end

          if attr_object[:model]
            set_attribute_history(attr_object[:prefix], x.to_s, attr_object[:model])
          end

          # try to set value for extra atrributes
          self.instance_variable_set("@#{@extra_attribute_keys.last}", attr_object[:model].try(x.to_s))
        end
      end
    end

    # Set attribute history updates the attrube_lookup object
    # @param prefix is the attribute prefix [String] the prefix the form_object gave this attribute
    # @param key is name of the original method from the model [String]
    # @param model ActiveRecord class of the method [ActiveRecord]
    def set_attribute_history(prefix=nil, key, model)
      if prefix
        attribute_lookup.merge!("#{prefix}_#{key}": { original_method: key, model: instance_of_model(model).class.name })
      else
        attribute_lookup.merge!("#{key}": { original_method: key, model: instance_of_model(model).class.name })
      end 
    end

    # This method is reponsible for taking an ActiveRecord class and turning it into snake cased prefix
    # @param pluralize determines if the prefix is going to be plural or not [Boolean]
    # @param model ActiveRecord class [ActiveRecord]
    def model_prefix(model, pluralize: false)
      if pluralize
        instance_of_model(model).class.name.pluralize.gsub('::','_').underscore
      else
        instance_of_model(model).class.name.gsub('::','_').underscore
      end
    end

    # Instance of model gives the DSL the flexibility to have an instance of an ActiveRecord class or the class it self.
    # This method will take an argument of either an ActiveRecord class instance or class definiton and return the an instance
    # @param model ActiveRecord class or instance [ActiveRecord]
    # @return ActiveRecord model instance [ActiveRecord]
    def instance_of_model(model)
      model.respond_to?(:new) ? model.new : model
    end

    def class_for(model)
      model.respond_to?(:new) ? model : model.class
    end

    def model_is_activerecord?(model)
      return if model.nil?

      unless class_for(model).ancestors.include?(ActiveRecord::Base)
        raise ArgumentError, 'Model must be an ActiveRecord descendant'
      end
    end

    # The attribute lookup method is a hash that has the form object attribute as a key and the history of that atrribute as the value
    # EXAMPLE:
    # {
    #   car_color: { original_method: 'color', model: 'Car' }
    # }
    # 
    # @return hash [Hash]
    def attribute_lookup
      @attribute_lookup ||= {}
    end
  end
end
