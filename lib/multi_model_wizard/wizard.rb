# frozen_string_literal: true

# Modules
require 'multi_model_wizard/redis_cookie_store'
require 'multi_model_wizard/dynamic_validation'
require 'multi_model_wizard/cookie_store'
require 'multi_model_wizard/version'
require 'multi_model_wizard/config'
require 'multi_model_wizard'
require 'form_object/base'

# Third party gems
require 'json'
require 'securerandom'
require 'active_support'

module MultiModelWizard
  module Wizard
    extend ActiveSupport::Concern

    include ::MultiModelWizard::CookieStore
    include ::MultiModelWizard::RedisCookieStore

    attr_reader :form_id

    # This gets the form data from the session cookie or redis depending on whats configured
    def session_params
      store_in_redis? ? redis_session_params : cookie_session_params
    end
  
    # This clears the form data from the session cookie or redis depending on whats configured
    def clear_session_params
      store_in_redis? ? clear_redis_session_params : clear_cookie_session_params
    end

    # This sets the form data in the session cookie or redis depending on whats configured
    def set_session_params(value)
      store_in_redis? ? set_redis_session_params(value) : set_cookie_session_params(value)
    end
  
    # Wizard form uuid will attempt to get the uuid from the browser session cookie
    # If one is not there it will set a new session cookie with the uuid as teh value
    def wizard_form_uuid
      key = if form_id
        "#{multi_model_wizard_form_key}#{form_id}".to_sym
      else
        multi_model_wizard_form_key
      end
      return get_signed_cookie(key) if get_signed_cookie(key).present?

      @uuid ||= SecureRandom.uuid
      set_signed_cookie(key: key, value: @uuid)
      @uuid
    end

    # Reference the form key that was passed in from the initializer
    def multi_model_wizard_form_key
      ::MultiModelWizard.configuration.form_key
    end

    private

    # Logical methods to determine where the gem should store form data
    def store_in_redis?
      ::MultiModelWizard.configuration.store_in_redis?
    end

    # This method is used to retrieve the form data from redis
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
  end
end
