class AddCitationToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :citation, :string
  end

  def change
    remove column :publications, :citation, :string
  end

  def self.down
    remove_column :publications, :citation, :string
  end
end
