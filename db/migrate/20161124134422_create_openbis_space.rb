class CreateOpenbisSpace < ActiveRecord::Migration
  def change
    create_table :openbis_spaces do |t|
      t.string :url
      t.string :space_name
      t.string :username
      t.string :password
      t.integer :project_id
      t.timestamps
    end
  end

end
