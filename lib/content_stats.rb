class ContentStats
  
  class ProjectStats
    attr_accessor :project,:sops,:data_files,:models,:publications,:people,:assays,:studies,:investigations, :user
    
    def initialize
      @user=User.first
    end
    
    def data_files_size
      assets_size data_files
    end
    
    def sops_size
      assets_size sops
    end
    
    def models_size
      assets_size models
    end
    
    def visible_data_files
      visible_assets data_files
    end
    
    def visible_sops
      visible_assets sops
    end
    
    def visible_models
      visible_assets models
    end
    
    def registered_people
      people.select{|p| !p.user.nil?}
    end
    
    private 
    
    def visible_assets assets
      assets.select{|asset| Authorization.is_authorized?('show',nil,asset.resource,@user)}
    end
    
    def assets_size assets
      size=0
      assets.each do |asset|
        size += asset.resource.content_blob.data.size unless asset.resource.content_blob.data.nil?
      end
      return size
    end
  end  
  
  
  def self.generate    
    result=[]    
    Project.all.each do |project|
      project_stats=ProjectStats.new
      project_stats.project=project
      project_stats.sops=project.assets.select{|a| a.resource.kind_of?(Sop)}
      project_stats.models=project.assets.select{|a| a.resource.kind_of?(Model)}
      project_stats.data_files=project.assets.select{|a| a.resource.kind_of?(DataFile)}
      project_stats.publications=project.publications
      project_stats.people=project.people
      project_stats.assays=project.assays
      project_stats.studies=project.studies
      result << project_stats           
    end
    return result
  end
  
end