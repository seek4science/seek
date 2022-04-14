class CreateRoleTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :role_types do |t|
      t.string :title
      t.string :key
      t.string :scope
      t.timestamps
    end
  end
end
