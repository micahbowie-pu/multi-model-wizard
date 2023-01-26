# frozen_string_literal: true

require 'spec_helper'
require 'multi_model_wizard/dynamic_validation'

RSpec.describe MultiModelWizard::DynamicValidation do
  let(:dummy_class) { Class.new { include MultiModelWizard::DynamicValidation } }
  let(:test_class) { dummy_class.new }

  describe '#validate_attribute?' do
    context 'when there are no validations for the attribute' do
      it 'returns true' do
        vehicle = Vehicle.new(kind: 'car', note: 'a note', manufacturer_id: 1)

        expect(test_class.valid_attribute?(:note, model_instance: vehicle)).to be(true)
      end
    end

    context 'when the attribute doesnt exist' do
      it 'returns true' do
        vehicle = Vehicle.new(kind: 'car', manufacturer_id: 1)

        expect(test_class.valid_attribute?(:fake_atrribute, model_instance: vehicle)).to be(true)
      end
    end

    context 'when the attribute is invalid' do
      it 'returns false' do
        vehicle = Vehicle.new(kind: nil, manufacturer_id: 1)

        expect(test_class.valid_attribute?(:kind, model_instance: vehicle)).to be(false)
      end

      context 'only validates the attributes passed to method' do
        it 'returns true' do
          vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: 1)

          expect(test_class.valid_attribute?(:note, model_instance: vehicle)).to be(true)
        end
      end

      context 'when one of many attributes is invalid' do
        it 'returns false' do
          vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: 1)

          expect(test_class.valid_attribute?(:note, :kind, model_instance: vehicle)).to be(false)
        end
      end
    end
  end

  describe '#validate_attribute_with_message' do
    it 'returns the an object' do
      vehicle = Car.new(wheels: 3, kind: nil, manufacturer_id: nil)
      output = test_class.validate_attribute_with_message(:wheels, :kind, model_instance: vehicle)

      expect(output).to be_a(OpenStruct)
    end

    it 'return object can provide valid status' do
      vehicle = Car.new(wheels: 3, kind: nil, manufacturer_id: nil)
      output = test_class.validate_attribute_with_message(:wheels, :kind, model_instance: vehicle)

      expect(output.valid).to be(false)
    end

    it 'return object can provide error messages' do
      vehicle = Car.new(wheels: 3, kind: nil, manufacturer_id: nil)
      output = test_class.validate_attribute_with_message(:wheels, :kind, model_instance: vehicle)

      expect(output.messages).to eq(["Wheels must be equal to 4", "Kind can't be blank"])
    end

    context 'when there are no validations for the attribute' do
      it 'returns true' do
        vehicle = Vehicle.new(kind: 'car', note: 'a note', manufacturer_id: 1)
        output = test_class.validate_attribute_with_message(:note, model_instance: vehicle)

        expect(output.valid).to be(true)
      end
    end

    context 'when the attribute doesnt exist' do
      it 'returns true' do
        vehicle = Vehicle.new(kind: 'car', manufacturer_id: 1)
        output = test_class.validate_attribute_with_message(:fake_atrribute, model_instance: vehicle)

        expect(output.valid).to be(true)
      end
    end

    context 'when the attribute is invalid' do
      it 'returns false' do
        vehicle = Vehicle.new(kind: nil, manufacturer_id: 1)
        output = test_class.validate_attribute_with_message(:kind, model_instance: vehicle)

        expect(output.valid).to be(false)
      end

      it 'returns the error messages' do
        vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: 1)
        output = test_class.validate_attribute_with_message(:kind, model_instance: vehicle)

        expect(output.messages).to eq(["Kind can't be blank"])
      end

      context 'only validates the attributes passed to method' do
        it 'returns true' do
          vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: 1)
          output = test_class.validate_attribute_with_message(:note, model_instance: vehicle)

          expect(output.valid).to be(true)
        end
      end

      context 'when one of many attributes is invalid' do
        it 'returns false' do
          vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: 1)
          output = test_class.validate_attribute_with_message(:note, :kind, model_instance: vehicle)

          expect(output.valid).to be(false)
        end

        it 'returns the error messages' do
          vehicle = Vehicle.new(note: 'notie', kind: nil, manufacturer_id: nil)
          output = test_class.validate_attribute_with_message(:note, :kind, :manufacturer_id, model_instance: vehicle)

          expect(output.messages).to eq(["Kind can't be blank", "Manufacturer can't be blank"])
        end
      end

      context 'it validates using parent validations and its own validations' do 
        it 'returns the error messages' do
          vehicle = Car.new(wheels: 3, kind: nil, manufacturer_id: nil)
          output = test_class.validate_attribute_with_message(:wheels, :kind, model_instance: vehicle)

          expect(output.messages).to eq(["Wheels must be equal to 4", "Kind can't be blank"])
        end

        it 'returns true' do
          vehicle = Car.new(wheels: 3, kind: nil, manufacturer_id: nil)
          output = test_class.validate_attribute_with_message(:wheels, :kind, model_instance: vehicle)
          expect(output.messages).to eq(["Wheels must be equal to 4", "Kind can't be blank"])
        end
      end
    end
  end
end
