module Seek
  class ContentStats

    AUTHORISED_TYPES=[Investigation,Study,Assay,DataFile,Model,Sop,Presentation]
    
    class ProjectStats
      attr_accessor :project,:sops,:data_files,:models,:publications,:people,:assays,:studies,:investigations,:presentations, :user
      
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

      AUTHORISED_TYPES.each do |type|
        type_class_name = type.name
        type_str=type_class_name.underscore.pluralize

        define_method "publicly_visible_#{type_str}" do |projects|
          authorised_assets type_class_name,"view",projects, nil
        end

        define_method "publicly_accessible_#{type_str}" do |projects|
          authorised_assets type_class_name,"download",projects, nil
        end

      end
      
      def registered_people
        people.select{|p| !p.user.nil?}
      end
      
      private

      def authorised_assets asset_type,action, projects, user
        asset_type.constantize.all_authorized_for(action, user,projects)
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
        project_stats.people=project.people
        AUTHORISED_TYPES.each do |type|
          type_str=type.name.underscore.pluralize
          project_stats.send(type_str+"=",project.send(type_str))
        end

        project_stats.publications=project.publications
        result << project_stats
      end
      return result
    end
    
  end
end