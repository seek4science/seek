class AddDescriptionToSampleType < ActiveRecord::Migration
  def change
    add_column :sample_types, :description, :text
  end
end
