class AddIsIsajsonCompliantToInvestigations < ActiveRecord::Migration[6.1]
  def change
    add_column :investigations, :is_ISA_JSON_compliant, :boolean
  end
end
