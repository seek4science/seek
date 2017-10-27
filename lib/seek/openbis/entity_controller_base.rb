module Seek
  module Openbis
    module EntityControllerBase

      def self.included(base)
        base.before_filter :get_project
        base.before_filter :get_endpoint
        base.before_filter :get_entity, only: [:show, :edit, :register, :update]
        base.before_filter :prepare_asset, only: [:show, :edit, :register, :update]
      end

      def get_endpoint
        @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
      end

      def get_project
        @project = Project.find(params[:project_id])
      end

      def prepare_asset
        @asset = OpenbisExternalAsset.find_or_create_by_entity(@entity)
      end

      def seek_util
        @seek_util ||= Seek::Openbis::SeekUtil.new
      end


    end
  end
end

