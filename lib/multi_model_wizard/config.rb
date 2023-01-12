module MultiModelWizard
  class Config
    attr_accessor :store, :form_key

    def initialize
      @store = { location: :cookies, redis_instance: nil }
      @form_key = 'multi_model_wizard_form'
    end

    def redis_instance
      store[:redis_instance]
    end

    def location
      store[:location]
    end

    def store_in_redis?
      store[:location] == :redis
    end

    def store_in_cookies?
      store[:location] =! :redis
    end
  end
end
