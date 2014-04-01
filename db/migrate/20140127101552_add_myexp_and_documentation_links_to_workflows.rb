class AddMyexpAndDocumentationLinksToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :myexperiment_link, :string
    add_column :workflows, :documentation_link, :string
  end
end
