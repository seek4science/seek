class AddEncryptedPasswordToOpenbisEndpoint < ActiveRecord::Migration
  def change
    add_column :openbis_endpoints,:encrypted_password,:string
    add_column :openbis_endpoints, :encrypted_password_iv,:string
  end
end
