class AddEncryptedValueFieldsToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :encrypted_value, :text
    add_column :settings, :encrypted_value_iv, :string
  end
end
