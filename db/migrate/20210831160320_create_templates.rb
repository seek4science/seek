class CreateTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :templates do |t|
      t.string :title
      t.string :group
      t.integer :group_order
      t.string :temporary_name
      t.string :template_version
      t.string :isa_config
      t.string :isa_measurement_type
      t.string :isa_technology_type
      t.string :isa_protocol_type
      t.string :repo_schema_id
      t.string :organism
      t.string :level
      t.text :description
      t.integer :policy_id
      t.integer :contributor_id
      t.string :deleted_contributor, default: nil

      t.timestamps
    end
    add_index :templates, [:title, :group], name: 'index_templates_title_group'
  end
end
