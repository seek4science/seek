class AddDoiToPresentations < ActiveRecord::Migration[7.2]
  def change
    add_column :presentations, :doi, :string
    add_column :presentation_versions, :doi, :string
  end
end
