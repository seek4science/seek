class CreateToolAnnotations < ActiveRecord::Migration[6.1]
  def change
    create_table :tool_annotations do |t|
      t.references :resource, polymorphic: true
      t.string :bio_tools_id
      t.string :name
      t.timestamps
    end
  end
end
