class AddDescriptionAndIriToSampleAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_attributes, :iri,  :string
    add_column :sample_attributes, :description, :text
  end
end
