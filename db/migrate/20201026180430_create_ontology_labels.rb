class CreateOntologyLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :ontology_labels do |t|
      t.string :label
      t.string :iri
      t.integer :sample_controlled_vocab_term_id
    end
  end
end
