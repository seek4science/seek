class RemovePersonResponsibleFromStudy < ActiveRecord::Migration[5.2]
  def change
    remove_column :studies, :person_responsible_id, :integer
  end
end
