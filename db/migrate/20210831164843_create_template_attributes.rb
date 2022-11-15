class CreateTemplateAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :template_attributes do |t|
      t.string :title
      t.string :short_name
      t.boolean :required, :default => false
      t.string :ontology_version
      t.text :description
      t.integer :template_id
      t.integer :sample_controlled_vocab_id
      t.integer :sample_attribute_type_id
      t.timestamps
    end
    add_index :template_attributes, [:template_id, :title], name: 'index_template_id_asset_id_title'
  end
end
