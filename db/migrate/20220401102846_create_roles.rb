class CreateRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :roles do |t|
      t.references :person
      t.references :role_type
      t.references :scope, polymorphic: true
      t.timestamps
    end
  end
end
