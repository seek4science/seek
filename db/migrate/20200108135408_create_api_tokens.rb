class CreateApiTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :api_tokens do |t|
      t.references :user
      t.string :title
      t.string :encrypted_token

      t.timestamps
    end

    add_index :api_tokens, :encrypted_token
  end
end
