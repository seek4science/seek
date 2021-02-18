class AddMissingColumnsChangeTitlePublicationsVersions < ActiveRecord::Migration[5.2]
  def change
    add_column "publication_versions","pubmed_id", :integer
    add_column "publication_versions","abstract", :text , limit: 16777215
    add_column "publication_versions","published_date", :date
    add_column "publication_versions","journal", :string
    add_column "publication_versions","citation", :text
    add_column "publication_versions","registered_mode", :integer
    add_column "publication_versions","booktitle", :text
    add_column "publication_versions","publisher", :string
    add_column "publication_versions","editor", :text
    add_column "publication_versions","publication_type_id", :integer
    add_column "publication_versions","url", :text

    change_column "publication_versions", "title", :text, :limit => 16777215
  end
end
