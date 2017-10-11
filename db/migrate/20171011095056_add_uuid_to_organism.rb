class AddUuidToOrganism < ActiveRecord::Migration
  def change
    add_column :organisms,:uuid,:string
  end
end
