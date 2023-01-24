# frozen_string_literal: true

require 'multi_model_wizard/cookie_store'
require 'multi_model_wizard/config'

require 'active_support'
require 'active_support/core_ext/numeric/time'

module MultiModelWizard
  module RedisCookieStore
    include ::MultiModelWizard::CookieStore

    # This method is used to set the form data in redis
    # @note the key of this method is the congifured form key and the uuid for that form session
    # EXAMPLE:
    # set_redis_cache('multi_model_wizard:d5be032f-4863-44e7-87c8-0ec86c85263d', { hello: 'world' })
    def set_redis_cache(key, data, expire: ::MultiModelWizard::CookieStore::EXPIRATION)
      wizard_redis_instance.set(key, data, ex: expire)
    end

    # This method is used to delete the form data from redis
    def clear_redis_cache(key)
      wizard_redis_instance.del(key)
    end
    
    # This method is used to retrieve the form data from redis
    def fetch_redis_cache(key)
      wizard_redis_instance.get(key)
    end

    private

    # Reference the redis instance that was passed in from the initializer
    def wizard_redis_instance
      ::MultiModelWizard.configuration.redis_instance
    end
  end
end
