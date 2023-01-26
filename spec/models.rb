# frozen_string_literal: true

require 'active_record'

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
