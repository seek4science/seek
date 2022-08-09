class AddServiceToInvestigations < ActiveRecord::Migration[6.1]
  def change
    add_reference :investigations, :service, foreign_key: true
  end
end
