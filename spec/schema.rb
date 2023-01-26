ActiveRecord::Schema.define do
  self.verbose = false

  create_table :vehicles, :force => true do |t|
    t.string :note
    t.string :kind
    t.integer :manufacturer_id

    t.timestamps
  end

end
