module Seek
  class ContentStats
    
    class ProjectStats
      attr_accessor :project,:sops,:data_files,:models,:publications,:people,:assays,:studies,:investigations, :user
      
      def initialize user
        @user=user
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
      
      def visible_data_files projects
        authorised_assets 'DataFile',"view", projects
      end
      
      def visible_sops projects
        authorised_assets 'Sop',"view", projects
      end
      
      def visible_models projects
        authorised_assets 'Model',"view", projects
      end
      
      def accessible_data_files projects
        authorised_assets 'DataFile',"download", projects
      end
      
      def accessible_sops projects
        authorised_assets 'Sop',"download", projects
      end
      
      def accessible_models projects
        authorised_assets 'Model',"download", projects
      end
      
      def registered_people
        people.select{|p| !p.user.nil?}
      end
      
      private

      def authorised_assets asset_type,action, projects
        asset_type.constantize.all_authorized_for(action, @user,projects)
      end
      
      def assets_size assets
        size=0
        assets.each do |asset|
          size += asset.content_blob.data.size unless asset.content_blob.data.nil?
        end
        return size
      end
    end

    def self.generate user
      result=[]
      Project.all.each do |project|
        project_stats=ProjectStats.new(user)
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
end