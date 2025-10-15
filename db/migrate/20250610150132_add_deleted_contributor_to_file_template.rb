class AddDeletedContributorToFileTemplate < ActiveRecord::Migration[7.2]
  def change
    add_column :file_templates, :deleted_contributor, :string
  end
end
