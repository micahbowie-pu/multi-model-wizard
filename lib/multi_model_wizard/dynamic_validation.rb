# frozen_string_literal: true

module MultiModelWizard
  module DynamicValidation
    def valid_attribute?(*attributes, model_instance:)
      errors.clear

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

      errors.empty?
    end

    def validate_attribute_with_message( *attributes, model_instance:)
      errors.clear

      attributes.flatten!
      attributes = attributes.first if attributes.first.is_a?(Hash)

      attributes.each do |attribute, value|
        validators = model_instance.class.ancestors.map { |x| x.try(:validators_on, attribute) }.compact.flatten

        validators.each { |validator| validator.validate(model_instance) }
      end

      return errors.empty?, errors.full_messages.uniq
    end
  end
end
