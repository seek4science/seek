class RemovePublicationTypeFromPublication < ActiveRecord::Migration
  def change
    remove_column :publications, :publication_type, :integer
  end
end
