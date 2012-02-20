class ProjectFolderAsset < ActiveRecord::Base
  belongs_to :asset,:polymorphic=>:true
  belongs_to :project_folder

  validates_presence_of :project_folder, :asset
  validate :correct_project

  private

  def correct_project
    prj = project_folder.try(:project)
    asset_projects = Array(asset.try(:projects))
    if !asset_projects.include?(prj)
      errors.add_to_base("Invalid asset projects for folder")
    end
  end
end
