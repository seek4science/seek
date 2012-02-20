class ProjectFolder < ActiveRecord::Base
  belongs_to :project
  belongs_to :parent,:class_name=>"ProjectFolder",:foreign_key=>:parent_id
  has_many :children,:class_name=>"ProjectFolder",:foreign_key=>:parent_id, :order=>:title, :after_add=>:update_child
  has_many :project_folder_assets, :dependent=>:destroy


  named_scope :root_folders, lambda { |project| {
    :conditions=>{:project_id=>project.id,:parent_id=>nil},:order=>"LOWER(title)"
    }
  }

  validates_presence_of :project,:title

  def update_child child
    child.project = project
    child.parent = self
  end

  def assets
    project_folder_assets.collect{|pfa| pfa.asset}
  end

  def self.new_items_folder project
    ProjectFolder.find(:first,:conditions=>{:project_id=>project.id,:incoming=>true})
  end

  #constucts the default project folders for a given project from a yaml file, by default using $RAILS_ROOT/config/default_data/default_project_folders.yml
  def self.initialize_default_folders project, yaml_path=File.join(Rails.root,"config","default_data","default_project_folders.yml")
    raise Exception.new("This project already has folders defined") unless ProjectFolder.root_folders(project).empty?

    yaml=YAML::load_file yaml_path
    folders={}

    #create individual folder items
    yaml.keys.each do |key|
      desc = yaml[key]
      new_folder=ProjectFolder.create :title=>desc["title"],
                                      :editable=>(desc["editable"].nil? ? true : desc["editable"]),
                                      :incoming=>(desc["incoming"].nil? ? false : desc["incoming"]),
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
            Rails.logger.error("Default project folder for key #{child} not found")
          end
        end
        parent.save!
      end
    end

    ProjectFolder.root_folders project
  end


  def add_assets assets
    assets = Array(assets)
    assets.each do |asset|
      ProjectFolderAsset.create :asset=>asset,:project_folder=>self
    end
  end

  #temporary method to destroy folders for a project, useful whilst developing
  def self.nuke project
    folders = ProjectFolder.find(:all,:conditions=>{:project_id=>project.id})
    folders.each {|f| f.destroy}
  end

  def to_json
      json = "{"
      json << "type: 'text',"
      json << "label: '#{title}',"
      json << "className: 'fred',"
      json << "expanded: 'true'"
      if children.empty?
        json << ", children: []"
      else
        json << ", children: ["
        children.sort_by(&:label).each do |child|
          json << child.to_json << ","
        end
        json << "]"
      end
      json << "}"
    end

end
