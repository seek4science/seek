class ProjectFolder < ActiveRecord::Base
  belongs_to :project
  belongs_to :parent,:class_name=>"ProjectFolder",:foreign_key=>:parent_id
  has_many :children,:class_name=>"ProjectFolder",:foreign_key=>:parent_id, :order=>:title, :after_add=>:update_child

  named_scope :root_folders, lambda { |project| {
    :conditions=>{:project_id=>project.id,:parent_id=>nil},:order=>:title
    }
  }

  validates_presence_of :project,:title

  def update_child child
    child.project = project
    child.parent = self
  end

  #constucts the default project folders for a given project from a yaml file, by default using $RAILS_ROOT/config/default_data/default_project_folders.yml
  def self.initialize_defaults project, yaml_path=File.join(Rails.root,"config","default_data","default_project_folders.yml")
    yaml=YAML::load_file yaml_path
    folders={}

    #create individual folder items
    yaml.keys.each do |key|
      desc = yaml[key]
      folders[key]=ProjectFolder.create :title=>desc["title"],:project=>project
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

end
