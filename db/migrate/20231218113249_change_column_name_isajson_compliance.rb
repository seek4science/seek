class ChangeColumnNameIsajsonCompliance < ActiveRecord::Migration[6.1]
  def change
    change_table :investigations do |t|
      t.rename :is_ISA_JSON_compliant, :is_isa_json_compliant
    end
  end
end
