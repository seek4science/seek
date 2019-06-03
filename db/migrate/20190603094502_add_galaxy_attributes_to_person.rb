class AddGalaxyAttributesToPerson < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :galaxy_instance, :string
    add_column :people, :galaxy_api_key, :string
  end
end
