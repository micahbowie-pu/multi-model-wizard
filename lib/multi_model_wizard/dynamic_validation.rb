# frozen_string_literal: true

module MultiModelWizard
  module DynamicValidation
    # Validates attributes using the original model and returns boolean for the given attributes
    # @params attributes are the names of the form objects methods [Symbol]
    # @params model_instance is the original model that the form object got the attributes from [ActiveRecord]
    # @returns returns boolean if the model has no errors [Boolean]
    def valid_attribute?(*attributes, model_instance:)
      model_instance.errors.clear

      attributes.flatten!
      attributes = attributes.first if attributes.first.is_a?(Hash)

      attributes.each do |attribute, validator_types|
        validators = model_instance.class.validators_on(attribute)

        if validator_types.present?
          validator_types = Array(validator_types)
          validators.select! { |validator| validator.kind.in?(validator_types) }
        end

        validators.each { |validator| validator.validate(model_instance) }
      end

      model_instance.errors.empty?
    end

    # Validates attributes using the original model and returns a boolean and a message for the given attributes
    # @params attributes are the names of the form objects methods [Symbol]
    # @params model_instance is the original model that the form object got the attributes from [ActiveRecord]
    # @returns returns an object with the valid and messages attributes [OpenStruct]
    def validate_attribute_with_message( *attributes, model_instance:)
      model_instance.errors.clear

      attributes.flatten!
      attributes = attributes.first if attributes.first.is_a?(Hash)

      attributes.each do |attribute, value|
        validators = model_instance.class.ancestors.map { |x| x.try(:validators_on, attribute) }.compact.flatten

        validators.each { |validator| validator.validate(model_instance) }
      end

      OpenStruct.new(valid: model_instance.errors.empty?, messages: model_instance.errors.full_messages.uniq )
    end
  end
end
