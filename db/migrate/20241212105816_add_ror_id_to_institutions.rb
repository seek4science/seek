class AddRorIdToInstitutions < ActiveRecord::Migration[6.1]
  def change
    add_column :institutions, :ror_id, :string
  end
end
