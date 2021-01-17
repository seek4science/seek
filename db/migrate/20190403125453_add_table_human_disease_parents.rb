class AddTableHumanDiseaseParents < ActiveRecord::Migration[4.2]
  def change
    create_table "human_disease_parents", id: false, force: :cascade do |t|
      t.integer "human_disease_id"
      t.integer "parent_id"
    end

    add_index "human_disease_parents", ["human_disease_id", "parent_id"], name: "index_disease_parents_on_disease_id_and_parent_id", using: :btree
    add_index "human_disease_parents", ["parent_id"], name: "index_disease_parents_on_parent_id", using: :btree
  end
end
