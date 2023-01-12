# frozen_string_literal: true

require 'active_model'
require 'multi_model_wizard/dynamic_validation'

module FormObject
  class Base
    include MultiModelWizard::DynamicValidation
    include ActiveModel::Model
    include ActiveModel::AttributeAssignment

    class << self
      # Creates a new instance of the form object with all models and configuration
      # @note This is how all forms should be instantiated
      # @param block [Block] this yields to a block with an instance of its self
      # @return form object [Wizards::FormObjects::Base]
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

    ATTRIBUTES = %i[
      current_step
      new_form
    ]

    attr_reader :extra_attributes, :models, :dynamic_models, :multiple_instance_models

    ATTRIBUTES.each { |attribute| attr_accessor attribute }

    def initialize
      @models = []
      @dynamic_models = []
      @multiple_instance_models = []
      @extra_attributes = []
    end

    # Needs to be overridden by child class.
    # @note This method needs to be overridden with your custom logic to create or update models from the form 
    # @note This method needs return a boolean after attempting to create the records 
    # @return boolean [Bolean] returns true if all model changes/creation persisted
    def persist!
      raise NotImplementedError
    end

    # Checks if the form and its attributes are valid
    # @note This method is here because the Wicked gem automagically runs this methdo to move to the next step
    # @note This method needs return a boolean after attempting to create the records 
    # @return boolean [Boolean]
    def save
      self.valid?
    end

    # Add a custom error message and makes the object invalid
    #
    def invalidate!(errors_msg)
      errors.add(:associated_model, errors_msg)
      errors.add(:associated_model, 'could not be properly save')
    end

    # Boolean method returns if the object is on the first step or not
    # @return boolean [Boolean]
    def first_step?
      return true unless current_step.to_sym

      form_steps.first == current_step.to_sym
    end

    # Gets all of the form objects present attributes and returns them in a hash
    # @note This method will only return a key value pair for attributes that are not nil
    # @note It ignores the models arrays, errors, etc. 
    # @return hash [ActiveSupport::HashWithIndifferentAccess]
    def attributes
      hash = ActiveSupport::HashWithIndifferentAccess.new
      self.instance_variables.each_with_object(hash) do |attribute, object|
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
      attributes.map do |single_attr|
        original_attribute = attribute_lookup.dig(single_attr.to_sym, :original_method)
        attribute_hash = { "#{original_attribute}": self.send(single_attr) }
        instance = attribute_lookup.dig(single_attr.to_sym, :model)&.constantize&.new
        instance&.send("#{original_attribute}=", self.send(single_attr))
        next if instance.nil?

        validation = validate_attribute_with_message(attribute_hash, model_instance: instance)
        if validation[0].eql?(false)
          validation[1].each { |err| self.errors.add(single_attr.to_sym, err) }
        end

        validation[0]
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
      model_instance = attribute_lookup.dig(attribute.to_sym, :model)&.constantize&.new
      return nil if model_instance.nil?

      self.send(attribute).map do |hash_instance|
        hash_instance.map do |key, value|
          model_instance&.send("#{key}=", value)

          validation = validate_attribute_with_message({ "#{key}": value }, model_instance: model_instance )
          if validation[0].eql?(false)
            validation[1].each { |err| self.errors.add(attribute.to_sym, err) }
          end
          validation[0]
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
      hash = { prefix: prefix, model: instance_of_model(model) }

      @dynamic_models << hash
    end

    def add_multiple_instance_model(attribute_name: nil, model:, instances: [])
      attribute_name = attribute_name || model_prefix(model, pluralize: true)
      hash = { attribute_name: attribute_name, model: instance_of_model(model), instances: instances }

      @multiple_instance_models << hash
    end

    def add_model(model, prefix: nil)
      hash = { prefix: prefix || model_prefix(model), model: instance_of_model(model) }

      @models << hash
    end

    def as_json
      instance_variables.each_with_object({}) do |var, obj|
          obj[var.to_s.gsub('@','')] = instance_variable_get(var)
      end.stringify_keys
    end

    def required_for_step?(step)
      return true if current_step == 'wicked_finish' || current_step.nil?

      form_steps.index(step.to_sym) <= form_steps.index(current_step.to_sym)
    end

    private

    def add_attribute(attribute_sym)
      ATTRIBUTES << attribute_sym
      self.class.send(:attr_accessor, attribute_sym)
    end

    def models_persisted?
      persist! ? true : errors.add(:associated_model, 'could not be properly save')
    end

    def all_models
      @all_models = (models + dynamic_models + multiple_instance_models).uniq
    end

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

    def set_attribute_history(prefix=nil, key, model)
      if prefix
        attribute_lookup.merge!("#{prefix}_#{key}": { original_method: key, model: instance_of_model(model).class.name })
      else
        attribute_lookup.merge!("#{key}": { original_method: key, model: instance_of_model(model).class.name })
      end 
    end

    def model_prefix(model, pluralize: false)
      if pluralize
        instance_of_model(model).class.name.pluralize.gsub('::','_').underscore
      else
        instance_of_model(model).class.name.gsub('::','_').underscore
      end
    end

    def instance_of_model(model)
      model.respond_to?(:new) ? model.new : model
    end

    def attribute_lookup
      @attribute_lookup ||= {}
    end
  end
end
