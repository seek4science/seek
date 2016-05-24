class CreateSamples < ActiveRecord::Migration
  def change
    create_table :samples do |t|
      t.string :title
      t.integer :sample_type_id
      t.text :json_metadata
      t.string :uuid
      t.integer :contributor_id
      t.integer :policy_id
      t.string :contributor_type

      t.timestamps
    end
  end
end
