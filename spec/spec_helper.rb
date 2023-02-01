# frozen_string_literal: true

require 'byebug'
require 'active_record'
require 'multi_model_wizard'
require_relative 'models'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/schema.rb'
require File.dirname(__FILE__) + '/models.rb'

RSpec.configure do |config|
  config.include MultiModelWizard
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
