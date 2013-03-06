class AddIndexesOnTheAssetProjectJoinTables < ActiveRecord::Migration
  def self.up
    add_index :organisms_projects,[:organism_id,:project_id]
    add_index :data_files_projects,[:data_file_id,:project_id]
    add_index :presentations_projects,[:presentation_id,:project_id]
    add_index :data_files_projects,[:data_file_id,:project_id]
    add_index :events_projects,[:event_id,:project_id]
    add_index :investigations_projects,[:investigation_id,:project_id]
    add_index :models_projects,[:model_id,:project_id]
    add_index :presentations_projects,[:presentation_id,:project_id]
    add_index :projects_publications,[:publication_id,:project_id]

    add_index :organisms_projects,:project_id
    add_index :data_files_projects,:project_id
    add_index :presentations_projects,:project_id
    add_index :data_files_projects,:project_id
    add_index :events_projects,:project_id
    add_index :investigations_projects,:project_id
    add_index :models_projects,:project_id
    add_index :presentations_projects,:project_id
    add_index :projects_publications,:project_id

  end

  def self.down
    remove_index :organisms_projects,[:organism_id,:project_id]
    remove_index :data_files_projects,[:data_file_id,:project_id]
    remove_index :presentations_projects,[:presentation_id,:project_id]
    remove_index :data_files_projects,[:data_file_id,:project_id]
    remove_index :events_projects,[:event_id,:project_id]
    remove_index :investigations_projects,[:investigation_id,:project_id]
    remove_index :models_projects,[:model_id,:project_id]
    remove_index :presentations_projects,[:presentation_id,:project_id]
    remove_index :projects_publications,[:publication_id,:project_id]

    remove_index :organisms_projects,:project_id
    remove_index :data_files_projects,:project_id
    remove_index :presentations_projects,:project_id
    remove_index :data_files_projects,:project_id
    remove_index :events_projects,:project_id
    remove_index :investigations_projects,:project_id
    remove_index :models_projects,:project_id
    remove_index :presentations_projects,:project_id
    remove_index :projects_publications,:project_id
  end
end
