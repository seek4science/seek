class AddOtherCreatorsToInvestigation < ActiveRecord::Migration
  def change
    add_column :investigations, :other_creators, :text
  end
end
