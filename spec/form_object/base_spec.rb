# frozen_string_literal: true

require 'spec_helper'
require 'form_object/base'

RSpec.describe FormObject::Base do
  describe '#form_steps' do
    it 'returns form steps from child class' do
      steps = %i[
        basic_configuration
        body
        engine
        review
      ]

      expect(CustomVehicleForm.form_steps).to eq(steps)
    end
  end

  describe '#create_form' do
    it 'returns an instance of itself' do
      form = CustomVehicleForm.create_form {  }

      expect(form).to be_a(CustomVehicleForm)
    end

    it 'initializes an instance of itself with the correct attributes' do
      form = CustomVehicleForm.create_form { |form| form.add_model Car }

      expect(form).to respond_to(:car_manufacturer_id)
      expect(form).to respond_to(:car_wheels)
      expect(form).to respond_to(:car_kind)
      expect(form).to respond_to(:car_note)
    end

    it 'initializes an instance of itself with the correct attributes and values' do
      car = Car.new(kind: 'car', note: 'Bowies car')
      form = CustomVehicleForm.create_form { |form| form.add_model car }

      expect(form).to respond_to(:car_kind)
      expect(form).to respond_to(:car_note)
      expect(form.car_kind).to eq('car')
      expect(form.car_note).to eq('Bowies car')
    end
  end

  describe 'ATTRIBUTES' do
    it 'initializes with the current_step attribute' do
      form = CustomVehicleForm.new

      expect(form).to respond_to(:current_step)
    end

    it 'initializes with the new_form attribute' do
      form = CustomVehicleForm.new

      expect(form).to respond_to(:new_form)
    end
  end

  describe '#initialize' do 
    it 'sets new_form to true' do
      form = CustomVehicleForm.new

      expect(form.new_form?).to eq(true)
    end
  end

  describe '#save' do 
    it 'calls valid?' do
      form = CustomVehicleForm.new

      expect(form).to receive(:valid?)

      form.save
    end
  end

  describe '#invalidate!' do 
    it 'calls adds errors to to the form object' do
      form = CustomVehicleForm.new

      expect { form.invalidate!('fake news') }.to change { form.errors.count }
      expect(form.errors.full_messages).to eq(["Associated model fake news", "Associated model could not be properly save"])
    end

    it 'adds default error message associated models' do
      form = CustomVehicleForm.new

      form.invalidate!

      expect(form.errors.full_messages).to eq(["Associated model could not be properly save"])
    end
  end

  describe '#first_step' do 
    it 'returns true if the curernt step is equal to the first item in the form_steps' do
      form = CustomVehicleForm.new
      form.current_step = :basic_configuration

      expect(form.first_step?).to eq(true)
    end

    it 'returns false if the curernt step is NOT equal to the first item in the form_steps' do
      form = CustomVehicleForm.new
      form.current_step = :engine

      expect(form.first_step?).to eq(false)
    end

    it 'returns false if given a fake step' do
      form = CustomVehicleForm.new
      form.current_step = :fake_step

      expect(form.first_step?).to eq(false)
    end

    it 'returns can evaluate a string' do
      form = CustomVehicleForm.new
      form.current_step = 'basic_configuration'

      expect(form.first_step?).to eq(true)
    end

    it 'returns false if the current_step is nil' do
      form = CustomVehicleForm.new

      expect(form.first_step?).to eq(false)
    end
  end


  describe '#attributes' do
    it 'returns all attributes from its model' do
      car = Car.new(kind: 'car', note: 'Micahs car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form).to have_attributes(car_kind: 'car', car_note: 'Micahs car')
      expect(form.attributes).to include(car_kind: 'car', car_note: 'Micahs car')
    end

    it 'does not return private attributes' do
      private_attributes = %i[errors validation_context models @dynamic_models
                                  multiple_instance_models extra_attributes]

      car = Car.new(kind: 'car', note: 'Micahs car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.attributes.keys).to_not include(private_attributes)
    end
  end

  describe '#attribute_keys' do
    it 'includes attributes from its model' do
      car = Car.new(kind: 'car', note: 'Micahs car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.attribute_keys).to include(:car_kind, :car_note)
    end
  end

  describe '#attributes_for' do
    it 'returns only the attributes for that class' do
      attributes = {
        created_at: Time.current,
        id: 23,
        kind: 'car', 
        manufacturer_id: 1, 
        note: 'Micahs car',
        updated_at: Time.current,
        wheels: 4,
      }.stringify_keys
      car = Car.new(attributes)
      form = CustomVehicleForm.create_form { |f| f.add_model car }


      expect(form.attributes_for(Car)).to eq(attributes)
    end

    it 'returns a hash with indifferentaccess' do
      attributes = {
        created_at: Time.current,
        id: 23,
        kind: 'car', 
        manufacturer_id: 1, 
        note: 'Micahs car',
        updated_at: Time.current,
        wheels: 4,
      }.stringify_keys
      car = Car.new(attributes)
      form = CustomVehicleForm.create_form { |f| f.add_model car }


      expect(form.attributes_for(Car)).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it 'returns an empty hash if the class is not recognized' do
      car = Car.new
      form = CustomVehicleForm.create_form { |f| f.add_model car }


      expect(form.attributes_for(Vehicle)).to eq({})
    end
  end

  describe '#set_attributes' do
    it 'sets attributes for form' do
      car = Car.new
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect { form.set_attributes(car_kind: 'car', car_manufacturer_id: 1, car_note: 'Micahs car') }.to \
        change { form.car_kind }
      expect(form.car_kind).to eq('car')
    end

    it 'does nothing if given invalid attributes' do
      car = Car.new
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      form.set_attributes(fake: 'im not reail')

      expect(form.attributes).to_not include('fake')
    end

    it 'returns its self' do
      car = Car.new
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.set_attributes(car_kind: 'car')).to be_a(CustomVehicleForm)
    end 
  end

  describe '#validate_attributes' do
    it 'returns a boolean based on an attributes validity' do
      car = Car.new(kind: 'car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.validate_attributes(:car_kind)).to eq(true)
    end
    it 'returns a boolean based on all attributes validity' do
      car = Car.new(kind: 'car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.validate_attributes(:car_kind, :car_manufacturer_id)).to eq(false)
    end

    it 'raises an error when given an argument thats not a symbol' do
      car = Car.new(kind: 'car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect { form.validate_attributes('car_kind') }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Attributes must be a Symbol'))
    end

    it 'raises an error when given an attribute that doesnt belong' do
      car = Car.new(kind: 'car')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect { form.validate_attributes(:car_kind, :fake_attribute) }.to \
        raise_error(an_instance_of(FormObject::AttributeNameError).and \
        having_attributes(message: 'fake_attribute is not a valid attribute of this form object'))
    end

    it 'adds error messages to the errors object' do
      car = Car.new
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect { form.validate_attributes(:car_kind) }.to change { form.errors.count }.by(1)
      expect(form.errors.full_messages).to eq(["Car kind Kind can't be blank"])
    end
  end

  describe '#add_multiple_instance_model' do
    it 'returns a boolean based on all the instances validity' do
      car = Car.new(kind: 'car')
      car_two = Car.new(kind: 'car', manufacturer_id: 1)
      form = CustomVehicleForm.create_form do |f| 
        f.add_multiple_instance_model attribute_name: 'cars', model: Car, instances: [car, car_two]
      end 

      expect(form.validate_multiple_instance_model(:cars)).to eq(false)
    end

    it 'raises an error when given an argument thats not a symbol' do
      car = Car.new(kind: 'car')
      car_two = Car.new(kind: 'car', manufacturer_id: 1)
      form = CustomVehicleForm.create_form do |f| 
        f.add_multiple_instance_model attribute_name: 'cars', model: Car, instances: [car, car_two]
      end 

      expect { form.validate_multiple_instance_model('car_kind') }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Attribute must be a Symbol'))
    end

    it 'raises an error when given an attribute that doesnt belong' do
      car = Car.new(kind: 'car')
      car_two = Car.new(kind: 'car', manufacturer_id: 1)
      form = CustomVehicleForm.create_form do |f| 
        f.add_multiple_instance_model attribute_name: 'cars', model: Car, instances: [car, car_two]
      end 

      expect { form.validate_multiple_instance_model(:fake_attribute) }.to \
        raise_error(an_instance_of(FormObject::AttributeNameError).and \
        having_attributes(message: 'fake_attribute is not a valid attribute of this form object'))
    end

    it 'adds error messages to the errors object' do
      car = Car.new(kind: 'car')
      car_two = Car.new(kind: 'car', manufacturer_id: 1)
      form = CustomVehicleForm.create_form do |f| 
        f.add_multiple_instance_model attribute_name: 'cars', model: Car, instances: [car, car_two]
      end 

      expect { form.validate_multiple_instance_model(:cars) }.to change { form.errors.count }.by(3)
    end
  end

  describe '#add_extra_attributes' do
    it 'adds attributes to the form object' do
      form = CustomVehicleForm.new

      form.add_extra_attributes(prefix: 'vehicle', attributes: %i[country_of_origin designer])
      form.send(:init_attributes)

      expect(form).to respond_to(:vehicle_designer)
      expect(form).to respond_to(:vehicle_country_of_origin)
    end

    it 'uses the model prefix is no prefix is given' do
      form = CustomVehicleForm.new

      form.add_extra_attributes(attributes: %i[country_of_origin designer], model: Car)
      form.send(:init_attributes)

      expect(form).to respond_to(:car_designer)
      expect(form).to respond_to(:car_country_of_origin)
    end

    it 'raises an error if the prefix is not a string' do
      form = CustomVehicleForm.new

      expect { form.add_extra_attributes(prefix: :vehicle, attributes: %i[country_of_origin designer])  }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Prefix must be a String'))
    end

    it 'raises an error if all the attributes are NOT symbols' do
      form = CustomVehicleForm.new

      expect { form.add_extra_attributes(attributes: [:country_of_origin, 'designer']) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'All attributes must be Symbols'))
    end
  end

  describe '#add_dynamic_model' do
    it 'raises an error if all the prefix are NOT symbols' do
      form = CustomVehicleForm.new

      expect { form.add_dynamic_model(prefix: :vehicle, model: Car) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Prefix must be a String'))
    end

    it 'raises an error if model is not the a descendant of ActiveRecord' do
      form = CustomVehicleForm.new

      expect { form.add_dynamic_model(prefix: 'vehicle', model: FakeModel) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Model must be an ActiveRecord descendant'))
    end


    it 'adds configuration to the dynamic_models' do
      form = CustomVehicleForm.new

      expect { form.add_dynamic_model(prefix: 'vehicle', model: Car) }.to \
        change { form.dynamic_models.count }.by 1
    end
  end

  describe '#add_multiple_instance_model' do
    it 'raises an error if all the attributes are NOT symbols' do
      form = CustomVehicleForm.new

      expect { form.add_multiple_instance_model(attribute_name: :vehicle, model: Car) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Attribute name must be a String'))
    end

    it 'raises an error if model is not the a descendant of ActiveRecord' do
      form = CustomVehicleForm.new

      expect { form.add_multiple_instance_model(attribute_name: 'vehicle', model: FakeModel) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Model must be an ActiveRecord descendant'))
    end

    it 'adds configuration to the multiple_instance_models' do
      form = CustomVehicleForm.new

      expect { form.add_multiple_instance_model(model: Car) }.to \
        change { form.multiple_instance_models.count }.by 1
    end
  end

  describe '#add_model' do
    it 'raises an error if all the prefix are NOT symbols' do
      form = CustomVehicleForm.new

      expect { form.add_model(Car, prefix: :vehicle) }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Prefix must be a String'))
    end

    it 'raises an error if model is not the a descendant of ActiveRecord' do
      form = CustomVehicleForm.new

      expect { form.add_model(FakeModel, prefix: 'vehicle') }.to \
        raise_error(an_instance_of(ArgumentError).and \
        having_attributes(message: 'Model must be an ActiveRecord descendant'))
    end

    it 'adds configuration to the models' do
      form = CustomVehicleForm.new

      expect { form.add_model(Car) }.to \
        change { form.models.count }.by 1
    end
  end

  describe '#as_json' do
    it 'returns a hash' do
      form = CustomVehicleForm.new

      form.add_model(Car)
      expect(form.as_json).to be_a(Hash)
    end

    it 'returns a hash with string keys' do
      car = Car.new(kind: 'bevo mobile')
      form = CustomVehicleForm.create_form { |f| f.add_model car }

      expect(form.as_json['car_kind']).to eq('bevo mobile')
    end
  end

  describe '#required_for_step?' do
    it 'returns true if the current_step is wicked_finish' do
      form = CustomVehicleForm.new
      form.current_step = 'wicked_finish'

      expect(form.required_for_step?(:basic_configuration)).to eq(true)
    end

    it 'returns true if the current_step is nil' do
      form = CustomVehicleForm.new
      form.current_step = nil

      expect(form.required_for_step?(:basic_configuration)).to eq(true)
    end

    it 'returns true if the current_step is equal to the step given' do
      form = CustomVehicleForm.new
      form.current_step = :basic_configuration

      expect(form.required_for_step?(:basic_configuration)).to eq(true)
    end

    it 'returns true if the current_step is greater in index than the step given' do
      form = CustomVehicleForm.new
      form.current_step = :body

      expect(form.required_for_step?(:basic_configuration)).to eq(true)
    end

    it 'returns false if the current_step is lesser in index than the step given' do
      form = CustomVehicleForm.new
      form.current_step = :basic_configuration

      expect(form.required_for_step?(:body)).to eq(false)
    end
  end

  describe '#persist!' do
    context 'when the form is new' do
      it 'calls create' do
        form = CustomVehicleForm.new

        expect(form).to receive(:create)

        form.persist!
      end
    end

    context 'when the form is NOT new' do
      it 'calls update' do
        form = CustomVehicleForm.new
        form.new_form = false

        expect(form).to receive(:update)

        form.persist!
      end
    end
  end
end
