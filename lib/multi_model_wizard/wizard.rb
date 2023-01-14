# frozen_string_literal: true

# Modules
require 'multi_model_wizard/redis_cookie_store'
require 'multi_model_wizard/dynamic_validation'
require 'multi_model_wizard/cookie_store'
require 'multi_model_wizard/version'
require 'multi_model_wizard/config'
require 'form_object/base'

# Third party gems
require 'wicked'
require 'json'
require 'securerandom'
require 'active_support'

module MultiModelWizard
  module Wizard
    include ::Wicked::Wizard
    include ::MultiModelWizard::CookieStore
    include ::MultiModelWizard::RedisCookieStore

    extend ActiveSupport::Concern

    def session_params
      store_in_redis? ? redis_session_params : cookie_session_params
    end
  
    def clear_session_params
      store_in_redis? ? clear_redis_session_params : clear_cookie_session_params
    end

    def set_session_params(value)
      store_in_redis? ? set_redis_session_params(value) : set_cookie_session_params(value)
    end
  
    def wizard_form_uuid
      key = multi_model_wizard_form_key.to_sym
      return get_signed_cookie(key) if get_signed_cookie(key).present?
  
      @uuid ||= SecureRandom.uuid
      set_signed_cookie(key: key, value: @uuid)
      @uuid
    end
  
    def multi_model_wizard_form_key
      ::MultiModelWizard.configuration.form_key
    end

    private

    def redis_session_params
      JSON.parse(fetch_redis_cache("#{multi_model_wizard_form_key}:#{wizard_form_uuid}"))
    rescue TypeError
      {}
    end

    def clear_redis_session_params
      clear_redis_cache("#{multi_model_wizard_form_key}:#{wizard_form_uuid}")
      delete_cookie(multi_model_wizard_form_key.to_sym)
    end

    def set_redis_session_params(value)
      set_redis_cache(
        "#{multi_model_wizard_form_key}:#{wizard_form_uuid}", 
        value,
      )
    end

    def cookie_session_params
      get_signed_cookie(multi_model_wizard_form_key)
    end

    def clear_cookie_session_params
      delete_cookie(key)
    end

    def set_cookie_session_params(attributes)
      set_signed_cookie(attributes.merge(key: multi_model_wizard_form_key))
    end

    def helper_method(method)
      method
    end
  end
end
