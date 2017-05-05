class ProjectFolderAsset < ActiveRecord::Base
  belongs_to :asset, polymorphic: :true
  belongs_to :project_folder

  validates_presence_of :project_folder, :asset
  validate :correct_project

  private

  def correct_project
    prj = project_folder.try(:project)
    asset_projects = Array(asset.try(:projects))
    unless asset_projects.include?(prj)
      errors[:base] << "Invalid asset #{I18n.t('project').pluralize} for folder"
    end
  end

  def self.assign_existing_assets(project)
    folder_for_new_assets = ProjectFolder.new_items_folder project
    unless folder_for_new_assets.nil?
      disable_authorization_checks do
        folder_for_new_assets.add_assets project.assets.select { |a| a.folders.empty? }
      end
    end
  end
end
