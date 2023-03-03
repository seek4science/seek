class ProjectFolder < ApplicationRecord
  before_destroy -> (folder) { throw :abort unless folder.deletable? }
  before_destroy :unsort_assets_and_remove_children

  belongs_to :project
  belongs_to :parent,:class_name=>"ProjectFolder",:foreign_key=>:parent_id
  has_many :children,-> { order(:title) }, :class_name=>"ProjectFolder",:foreign_key=>:parent_id, :after_add=>:update_child
  has_many :project_folder_assets, :dependent=>:destroy

  scope :root_folders, -> (project) { where(project_id: project.id, parent_id: nil).order(Arel.sql('LOWER(title)')) }

  validates_presence_of :project,:title

  def update_child child
    child.project = project
    child.parent = self
  end

  def assets
    project_folder_assets.collect(&:asset).reject{|a| a.class.name=='Collection'}
  end

  #assets that are authorized to be shown for the current user
  def authorized_assets
    assets.select(&:can_view?)
  end

  # assets that are not associated to any assay
  def authorized_hanging_assets
    assets.select do |a|
      is_sample = a.instance_of?(Sample)
      linked_to_assays = a&.assays.present?
      linked_to_studies = a&.studies.present? || (a&.study.present? if a&.respond_to?(:study))

      !is_sample && !linked_to_assays && !linked_to_studies && a&.can_view?
    end
  end

  #what is displayed in the tree
  def label
    "#{title} (#{authorized_assets.count})"
  end

  def count
    authorized_hanging_assets.count
  end

  def self.new_items_folder(project)
    ProjectFolder.where(project_id: project.id, incoming: true).first
  end

  #constucts the default project folders for a given project from a yaml file, by default using Rails.root/config/default_data/default_project_folders.yml
  def self.initialize_default_folders project, yaml_path=File.join(Rails.root,"config","default_data","default_project_folders.yml")
    raise Exception.new("This #{I18n.t('project')} already has folders defined") unless ProjectFolder.root_folders(project).empty?

    yaml = YAML.load(ERB.new(File.read(yaml_path)).result)
    folders={}

    #create individual folder items
    yaml.keys.each do |key|
      desc = yaml[key]
      new_folder=ProjectFolder.create :title=>desc["title"],
                                      :editable=>(desc["editable"].nil? ? true : desc["editable"]),
                                      :incoming=>(desc["incoming"].nil? ? false : desc["incoming"]),
                                      :deletable=>(desc["deletable"].nil? ? true : desc["deletable"]),
                                      :project=>project
      folders[key]=new_folder
    end

    #now assign children
    yaml.keys.each do |key|
      desc=yaml[key]
      if desc.has_key?("children")
        parent = folders[key]
        desc["children"].split(",").each do |child|
          folder = folders[child.strip]
          unless folder.nil?
            parent.children << folder
          else
            Rails.logger.error("Default #{I18n.t('project')} folder for key #{child} not found")
          end
        end
        parent.save!
      end
    end

    ProjectFolder.root_folders project
  end

  #adds a child with the given title, and makes sure the project is set correctly
  def add_child title
    child = ProjectFolder.new(:title=>title)
    children << child
    child
  end

  def add_assets assets
    assets = Array(assets)
    assets.each do |asset|
      pfa = ProjectFolderAsset.new :asset=>asset,:project_folder=>self
      pfa.save!
    end
  end

  #moves assets to this folder, from the source folder (source folder needed incase the asset belongs to more than 1 folder)
  def move_assets assets,source_folder
    assets=Array(assets)
    if (project_id == source_folder.project_id)
      assets.each do |asset|
        link = ProjectFolderAsset.where(:asset_id=>asset.id,:asset_type=>asset.class.name,:project_folder_id=>source_folder.id).first
        link.project_folder=self
        link.save!
      end
    end
  end

  #temporary method to destroy folders for a project, useful whilst developing
  def self.nuke project
    folders = ProjectFolder.where(project_id: project.id)
    folder_assets = ProjectFolderAsset.all.select{|pfa| pfa.project_folder.nil? || pfa.project_folder.try(:project_id)==project.id}
    folder_assets.each {|a| a.destroy}
    folders.each {|f| f.deletable=true ; f.destroy}

  end

  def unsort_assets_and_remove_children
    new_items_folder=ProjectFolder.new_items_folder(project)
    if (new_items_folder && !self.incoming?)
      disable_authorization_checks do
        new_items_folder.add_assets(assets)
      end
    end
    children.destroy_all
  end

end
