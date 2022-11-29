class AddOtherCreatorsToSampleTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :sample_types, :other_creators, :text
  end
end
