class AddTemplateIdToSampleType < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_types, :template_id, :integer
  end
end
