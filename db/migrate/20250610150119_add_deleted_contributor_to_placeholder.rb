class AddDeletedContributorToPlaceholder < ActiveRecord::Migration[7.2]
  def change
    add_column :placeholders, :deleted_contributor, :string
  end
end
