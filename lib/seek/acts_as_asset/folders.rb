module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to Folders
    module Folders
      module InstanceMethods
        def add_new_to_folder
          projects.each do |project|
            pf = ProjectFolder.new_items_folder project
            unless pf.nil?
              pf.add_assets self
            end
          end
        end

        def folders
          project_folder_assets.map { |pfa| pfa.project_folder }
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :project_folder_assets, as: :asset, dependent: :destroy
          after_create :add_new_to_folder
        end
      end
    end
  end
end
