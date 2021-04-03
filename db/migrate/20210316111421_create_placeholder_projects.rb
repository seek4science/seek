class CreatePlaceholderProjects < ActiveRecord::Migration[5.2]
  def change
  create_table "placeholders_projects",  force: :cascade do |t|
    t.bigint "placeholder_id"
    t.bigint "project_id"
    t.index ["placeholder_id", "project_id"], name: "index_ph_projects_on_ph_id_and_p_id"
    t.index ["placeholder_id"], name: "index_ph_projects_on_ph_id"
    t.index ["project_id"], name: "index_ph_projects_on_p_id"
  end

  end
end
