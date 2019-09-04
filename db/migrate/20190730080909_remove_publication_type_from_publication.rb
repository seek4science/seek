class RemovePublicationTypeFromPublication < ActiveRecord::Migration[4.2]
  def change
    remove_column :publications, :publication_type, :integer
  end
end
