module Seek
  module Openbis

    ALL_TYPES = 'ALL TYPES'.freeze
    ALL_STUDIES = 'ALL STUDIES'.freeze
    ALL_ASSAYS = 'ALL ASSAYS'.freeze
    ALL_DATASETS = 'ALL DATASETS'.freeze

    module EntityControllerBase

      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      def self.included(base)
        base.before_filter :get_endpoint
        base.before_filter :get_project
        base.before_filter :project_member?, except: [:show_dataset_files]

        base.before_filter :check_entity, only: [:show, :edit, :register, :update, :refresh]
        base.before_filter :prepare_asset, only: [:show, :edit, :register, :update, :refresh]
      end

      def refresh
        puts "------------\nREFRESH\n---------" if DEBUG

        seek_util.sync_asset_content(@asset)

        flash[:error] = "OBis synchronization failed: #{@asset.err_msg}" if @asset.failed?
        flash[:notice] = 'Updated OpenBis content' if @asset.synchronized?
        redirect_to action: 'edit'
      end

      def check_entity
        begin
          get_entity
        rescue Exception => e
          msg = seek_util.extract_err_message(e)
          flash[:error] = "Cannot access OBis: #{msg}"
          redirect_back # fallback_location: @project
        end
      end

      def get_endpoint
        @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
      end

      def get_project
        @project = @openbis_endpoint.project
      end

      def project_member?
        unless @project.has_member?(User.current_user)
          error('Must be a member of the project', 'No permission')
          return false
        end
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

      def get_sync_options(hash = nil)
        hash ||= params
        hash.fetch(:sync_options, {}).permit(:link_datasets, :link_assays, :link_dependent,
                                             { linked_datasets: [] }, { linked_assays: [] })
      end

      def back_to_index
        index
        render action: 'index'
      end

    end
  end
end

