class AddOtherCreatorsToSample < ActiveRecord::Migration
  def change
    add_column :samples, :other_creators, :text
  end
end
