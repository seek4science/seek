module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to Folders
    module Folders
      module InstanceMethods
        def add_new_to_folder
          projects.each do |project|
            pf = ProjectFolder.new_items_folder project
            pf.add_assets self unless pf.nil?
          end
        end

        def folders
          project_folder_assets.map(&:project_folder)
        end

        def register_folder_tree
          object = object_for_request
          # assign each folder id
          folder_params.each do |folder_id|
            folder_id = Integer(folder_id) rescue nil
            unless folder_id.nil?
              dest_folder = ProjectFolder.find(folder_id)
              dest_folder.assign_folder(object)
            end
          end
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :project_folder_assets, as: :asset, dependent: :destroy
          after_create :add_new_to_folder
            # TODO: Review actions that can affect folder_trees
          after_save :register_folder_tree, only: [:create, :create_metadata, :manage_update]
        end
      end
    end
  end
end
