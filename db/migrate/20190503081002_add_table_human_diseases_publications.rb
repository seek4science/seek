class AddTableHumanDiseasesPublications < ActiveRecord::Migration[5.2]
  def change
    create_table "human_diseases_publications", id: false, force: :cascade do |t|
      t.integer "human_disease_id"
      t.integer "publication_id"
    end

    add_index "human_diseases_publications", ["human_disease_id", "publication_id"], name: "index_diseases_publications_on_disease_id_and_publication_id", using: :btree
    add_index "human_diseases_publications", ["publication_id"], name: "index_diseases_publications_on_publication_id", using: :btree
  end
end
