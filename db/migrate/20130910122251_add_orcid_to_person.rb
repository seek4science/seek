class AddOrcidToPerson < ActiveRecord::Migration
  def change
    add_column :people, :orcid, :string, :default=>nil
  end
end
