class IncreaseCryptedPasswordLength < ActiveRecord::Migration
  def up
    change_column :users, :crypted_password, :string, limit: 64
  end

  def down
    change_column :users, :crypted_password, :string, limit: 40
  end
end
