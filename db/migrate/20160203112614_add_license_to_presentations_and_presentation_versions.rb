class AddLicenseToPresentationsAndPresentationVersions < ActiveRecord::Migration
  def change
    add_column :presentations, :license, :string
    add_column :presentation_versions, :license, :string
  end
end
