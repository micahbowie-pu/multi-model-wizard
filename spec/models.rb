# frozen_string_literal: true

require 'active_record'
require 'form_object/base'

# These models are used for testing only
#
# 
class Vehicle < ActiveRecord::Base
  validates :kind, presence: true
  validates :manufacturer_id, presence: true
end

class Car < Vehicle
  validates :wheels, numericality: { equal_to: 4 }
end

class FakeModel; end

# Test form object
#
#
class CustomVehicleForm < FormObject::Base
  cattr_accessor :form_steps do
    %i[
      basic_configuration
      body
      engine
      review
    ].freeze
  end

  def create
    created = false
    begin
        ActiveRecord::Base.transaction do
        car = Car.new(attributes_for(Car))
        car.parts = car_parts
        car.save!
        end
        created = true
    rescue StandardError => err
        return created       
    end
    created
  end

  def update
    updated = false
    begin
      ActiveRecord::Base.transaction do
        car = Car.find(car_id)
        car.attributes = attributes_for(Car)
        car.parts = car_parts
        car.save!
      end
      updated = true
    rescue StandardError => err
      return updated       
    end
    updated
  end
end
