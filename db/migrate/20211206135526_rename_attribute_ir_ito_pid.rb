class RenameAttributeIrItoPid < ActiveRecord::Migration[5.2]
  def change
    rename_column :sample_attributes, :iri, :pid
  end
end
