class AddIsTitleToSampleAttribute < ActiveRecord::Migration
  def change
    add_column :sample_attributes,:is_title,:boolean,:default=>false
  end
end
