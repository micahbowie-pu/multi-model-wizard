module MultiModelWizard
  class Config
    # The form key is what is used a the key in the session cookies
    # This can be changed in the intitializer file.
    # This key is also what is used as part of the redis key value pair 
    # if redis is configured.
    FORM_KEY = 'multi_model_wizard_form'.freeze

    attr_accessor :store, :form_key

    def initialize
      @store = { location: :cookies, redis_instance: nil }
      @form_key = FORM_KEY
    end

    # The configured redis instance. This is should be set in the initializer.
    # A redis instance is only needed if you are going to use redis to store.
    # Redis is great to use when you have a bigger/longer wizard form. 
    # Session cookies max size is 4k, so if the size is over that, consider
    # switching to redis store
    #
    #
    # Session cookies are still used even when using redis as the store location 
    # A key and a uuid is stored on the browser session cookie
    # That uuid is used as the key in redis to retrieve the form data to the controller
    def redis_instance
      store[:redis_instance]
    end

    # Location tells the gem where to put your form data between form steps
    # The default is session cookies in the browser
    def location
      store[:location]
    end

    # Logical methods to determine where the gem should store form data
    def store_in_redis?
      store[:location] == :redis
    end

    # Logical methods to determine where the gem should store form data
    def store_in_cookies?
      store[:location] =! :redis
    end
  end
end
