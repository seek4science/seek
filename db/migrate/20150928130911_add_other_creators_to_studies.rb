class AddOtherCreatorsToStudies < ActiveRecord::Migration
  def change
    add_column :studies, :other_creators, :text
  end
end
