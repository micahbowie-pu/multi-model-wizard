# frozen_string_literal: true

require 'active_record'

class Vehicle < ActiveRecord::Base
  validates :kind, presence: true
  validates :manufacturer_id, presence: true
end
