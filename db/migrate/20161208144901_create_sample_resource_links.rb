class CreateSampleResourceLinks < ActiveRecord::Migration
  def change
    create_table :sample_resource_links do |t|
      t.references :sample
      t.references :resource, polymorphic: true
    end

    add_index :sample_resource_links, :sample_id
    add_index :sample_resource_links, [:resource_id, :resource_type]
  end
end
