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
      authorised_assets data_files,"show"
    end
    
    def visible_sops
      authorised_assets sops,"show"
    end
    
    def visible_models
      authorised_assets models,"show"
    end
    
    def registered_people
      people.select{|p| !p.user.nil?}
    end
    
    private 
    
    def authorised_assets assets,action
      assets.select{|asset| Authorization.is_authorized?(action,nil,asset,@user)}
    end
    
    def assets_size assets
      size=0
      assets.each do |asset|
        size += asset.content_blob.data.size unless asset.content_blob.data.nil?
      end
      return size
    end
  end  
  
  
  def self.generate    
    result=[]    
    Project.all.each do |project|
      project_stats=ProjectStats.new
      project_stats.project=project
      project_stats.sops=project.sops
      project_stats.models=project.models
      project_stats.data_files=project.data_files
      project_stats.publications=project.publications
      project_stats.people=project.people
      project_stats.assays=project.assays
      project_stats.studies=project.studies
      project_stats.investigations=project.investigations
      result << project_stats           
    end
    return result
  end
  
end