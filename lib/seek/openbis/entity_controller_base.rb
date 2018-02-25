module Seek
  module Openbis

    ALL_TYPES = 'ALL TYPES'.freeze
    ALL_STUDIES = 'ALL STUDIES'.freeze
    ALL_ASSAYS = 'ALL ASSAYS'.freeze

    module EntityControllerBase

      def self.included(base)
        base.before_filter :get_endpoint
        base.before_filter :get_project
        base.before_filter :get_entity, only: [:show, :edit, :register, :update]
        base.before_filter :prepare_asset, only: [:show, :edit, :register, :update]
      end

      def get_endpoint
        @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
      end

      def get_project
        @project = @openbis_endpoint.project
      end

      def prepare_asset
        @asset = OpenbisExternalAsset.find_or_create_by_entity(@entity)
      end

      def seek_util
        @seek_util ||= Seek::Openbis::SeekUtil.new
      end

      def flash_issues(issues, canal = :error)
        return unless issues
        return if issues.empty?

        msg = issues.join(' <br>')
        msg = msg.html_safe
        flash[canal] = msg
      end

    end
  end
end

