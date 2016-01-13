class AddOtherCreatorsToAssay < ActiveRecord::Migration
  def change
    add_column :assays, :other_creators, :text
  end
end
