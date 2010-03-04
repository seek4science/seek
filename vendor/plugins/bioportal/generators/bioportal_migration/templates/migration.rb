class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    create_table :bioportal_concepts do |t|
      t.column :ontolgoy_id, :integer
      t.column :ontolgoy_version_id,:integer
      t.column :concept_id,:string
      t.column :cached_concept_yaml,:string
    end        
  end
  
  def self.down
    drop_table :bioportal_concepts
  end
end
