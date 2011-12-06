class CreateSpecialAuthCodes < ActiveRecord::Migration
  def self.up
    create_table :special_auth_codes do |t|
      t.string :code
      t.date :expiration_date
      t.string :asset_type
      t.integer :asset_id

      t.timestamps
    end
  end

  def self.down
    drop_table :special_auth_codes
  end
end
