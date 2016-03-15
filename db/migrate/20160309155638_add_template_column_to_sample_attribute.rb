class AddTemplateColumnToSampleAttribute < ActiveRecord::Migration
  def change
    add_column :sample_attributes, :template_column_index,:integer
  end
end
