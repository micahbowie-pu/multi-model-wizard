# frozen_string_literal: true

require_relative 'multi_model_wizard/dynamic_validation'
require_relative 'multi_model_wizard/redis_cookie_store'
require_relative 'multi_model_wizard/cookie_store'
require_relative 'multi_model_wizard/version'
require_relative 'multi_model_wizard/wizard'
require_relative 'multi_model_wizard/config'
require_relative 'form_object/base'


module MultiModelWizard
  class << self
    def configuration
      @configuration ||= ::MultiModelWizard::Config.new
    end

    def configure
      yield(configuration)
    end

    def version
      ::MultiModelWizard::VERSION
    end
  end
end
