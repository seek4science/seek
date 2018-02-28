class DeleteWorkflowAssociated < ActiveRecord::Migration
  def up
    associations = {
        annotations: [:annotatable_type],
        annotation_versions: [:annotatable_type],
        assay_assets: [:asset_type],
        assets_creators: [:asset_type],
        content_blobs: [:asset_type],
        favourites: [:resource_type],
        project_folder_assets: [:asset_type],
        relationships: [:subject_type, :other_object_type],
        sample_resource_links: [:resource_type],
        special_auth_codes: [:asset_type],
        subscriptions: [:subscribable_type],
        taggings: [:taggable_type]
    }

    models_to_remove = ['Workflow', 'Sweep', 'TavernaPlayer::Run']

    puts "Deleting workflow-related associations"
    models_to_remove.each do |model|
      associations.each do |table, fields|
        fields.each do |field|
          sql = "DELETE FROM #{table} WHERE #{field}='#{model}';"
          puts (execute(sql))
        end
      end
    end
    puts 'Done'
  end

  def down
  end
end
