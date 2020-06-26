class AddTableHumanDiseases < ActiveRecord::Migration[4.2]
  def change

    create_table "human_diseases", force: :cascade do |t|
      t.string   "title",        limit: 255
      t.string   "doid_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "first_letter", limit: 255
      t.string   "uuid",         limit: 255
    end
  
    create_table "human_diseases_projects", id: false, force: :cascade do |t|
      t.integer "human_disease_id"
      t.integer "project_id"
    end
  
    add_index "human_diseases_projects", ["human_disease_id", "project_id"], name: "index_diseases_projects_on_disease_id_and_project_id", using: :btree
    add_index "human_diseases_projects", ["project_id"], name: "index_diseases_projects_on_project_id", using: :btree

    create_table "assay_human_diseases", force: :cascade do |t|
      t.integer  "assay_id"
      t.integer  "human_disease_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  
    add_index "assay_human_diseases", ["assay_id"], name: "index_assay_diseases_on_assay_id", using: :btree
    add_index "assay_human_diseases", ["human_disease_id"], name: "index_assay_diseases_on_disease_id", using: :btree

    add_column :model_versions, :human_disease_id, :integer
    add_column :models, :human_disease_id, :integer
  end
end
