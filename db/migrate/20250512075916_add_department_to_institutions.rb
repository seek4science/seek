class AddDepartmentToInstitutions < ActiveRecord::Migration[7.2]
  def change
    add_column :institutions, :department, :string
  end
end
