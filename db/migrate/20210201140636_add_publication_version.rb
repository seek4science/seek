class AddPublicationVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :publications,:version, :integer,             limit: 4,     default: 1
  end
end
