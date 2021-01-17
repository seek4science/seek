class RemoveIdFromDocumentAuthLookup < ActiveRecord::Migration[5.2]
  def change
    remove_column :document_auth_lookup, :id, :primary_key
  end
end
