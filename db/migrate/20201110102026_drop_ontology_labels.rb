class DropOntologyLabels < ActiveRecord::Migration[5.2]
  def change
    drop_table :ontology_labels
  end
end
