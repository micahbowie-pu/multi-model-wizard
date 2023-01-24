# MultiModelWizard

Creates a smart object for your forms or wizards.This object can update and save multiple active record models at once.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add multi_model_wizard

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install mmulti_model_wizard

## Usage

Initialize the gem by creating an initializer file and then configuring your settings:
```
  # config/initializers/multi_model_wizard.rb
  #
  MultiModelWizard.configure do |config|
    config.store = { location: :redis, redis_instance: Redis.current }
    config.form_key = 'custom_car_wizard'
  end
```

Create a new form object that inherits from the base class. Make sure to override the `form_steps`, `create`, and `update`.
```
  # form_objects/custom_vehicle_form.rb
  #
  class CustomVehicleForm < FormObject::Base
    cattr_accessor :form_steps do
      %i[
        basic_configuration
        body
        engine
        review
      ].freeze
    end

    def create
      created = false
      begin
          ActiveRecord::Base.transaction do
          car = Car.new(attributes_for(Car))
          car.parts = car_parts
          car.save!
          end
          created = true
      rescue StandardError => err
          return created       
      end
      created
    end

    def update
      updated = false
      begin
        ActiveRecord::Base.transaction do
          car = Car.find(car_id)
          car.attributes = attributes_for(Car)
          car.parts = car_parts
          car.save!
        end
        updated = true
      rescue StandardError => err
        return updated       
      end
      updated
    end
  end
```

Use form in your controller:

```
 def set_car_form
    @form ||= Wizards::FormObjects::CarForm.create_form do |form|
                form.add_model Manufacturer
                form.add_model Dealer
                form.add_multiple_instance_model model: Parts, instances: parts
                form.add_dynamic_model prefix: 'vehicle', model: Vehicle
                form.add_extra_attributes prefix: 'vehicle', attributes: %i[leather_origin], model: Vehicle
              end
  end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Pull requests are welcome! Feel free to submit bugs as well.
