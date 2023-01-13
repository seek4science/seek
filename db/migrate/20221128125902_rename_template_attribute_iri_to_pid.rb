class RenameTemplateAttributeIriToPid < ActiveRecord::Migration[6.1]
  def change
    rename_column :template_attributes, :iri, :pid
  end
end