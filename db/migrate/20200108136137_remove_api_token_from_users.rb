class RemoveApiTokenFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_index :users, :api_token
    remove_column :users, :api_token, :string
  end
end
