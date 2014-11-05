class AddSuggestedTechnologyTypeToAssay < ActiveRecord::Migration
  def change
    add_column :assays, :suggested_technology_type_id,:integer
  end
end
