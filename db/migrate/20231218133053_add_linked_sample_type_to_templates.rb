class AddLinkedSampleTypeToTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column :template_attributes, :linked_sample_type_id, :integer
  end
end
