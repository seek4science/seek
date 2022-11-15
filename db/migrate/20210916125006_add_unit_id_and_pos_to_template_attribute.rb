class AddUnitIdAndPosToTemplateAttribute < ActiveRecord::Migration[5.2]
  def change
    add_column :template_attributes, :unit_id, :integer
    add_column :template_attributes, :pos, :integer
  end
end
