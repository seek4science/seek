class AddOtherCreatorsToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :other_creators, :text
    add_column :document_versions, :other_creators, :text
  end
end
