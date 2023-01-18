# frozen_string_literal: true

require 'multi_model_wizard/cookie_store'
require 'multi_model_wizard/config'
require 'multi_model_wizard/wizard'

require 'active_support'
require 'active_support/core_ext/numeric/time'

module MultiModelWizard
  module RedisCookieStore
    include ::MultiModelWizard::CookieStore

    def set_redis_cache(key, data, expire: nil)
      wizard_redis_instance.set(key, data, ex: expire || ::MultiModelWizard::CookieStore::EXPIRATION)
    end

    def clear_redis_cache(key)
      wizard_redis_instance.del(key)
    end

    def fetch_redis_cache(key)
      wizard_redis_instance.get(key)
    end

    private

    def wizard_redis_instance
      ::MultiModelWizard.configuration.redis_instance
    end
  end
end
