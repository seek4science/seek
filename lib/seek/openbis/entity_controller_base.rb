module Seek
  module Openbis
    ALL_TYPES = 'ALL TYPES'.freeze
    ALL_STUDIES = 'ALL STUDIES'.freeze
    ALL_ASSAYS = 'ALL ASSAYS'.freeze
    ALL_DATASETS = 'ALL DATASETS'.freeze

    # Used to provide common operations for openbis related controllers
    module EntityControllerBase
      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      def self.included(base)
        base.before_filter :get_endpoint
        base.before_filter :get_project
        base.before_filter :project_member?

        base.before_filter :check_entity, only: %i[show edit register update refresh show_dataset_files]
        base.before_filter :prepare_asset, only: %i[show edit register update refresh show_dataset_files]
      end

      def refresh
        seek_util.sync_asset_content(@asset)

        flash[:error] = "OBis synchronization failed: #{@asset.err_msg}" if @asset.failed?
        flash[:notice] = 'Updated OpenBis content' if @asset.synchronized?
        redirect_to @asset.seek_entity
      end

      def check_entity
        get_entity
      rescue => e
        msg = seek_util.extract_err_message(e)
        flash[:error] = "Cannot access OBis: #{msg}"
        redirect_back # fallback_location: @project
      end

      def newly_created
        @newly_created ||= []
      end

      def get_endpoint
        @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
      end

      def get_project
        @project = @openbis_endpoint.project
      end

      def project_member?
        return true if @project.has_member?(User.current_user)
        error('Must be a member of the project', 'No permission')
        false
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
        hash.fetch(:sync_options, {}).permit(:link_datasets, :link_assays, :link_dependent, :new_arrivals,
                                             { linked_datasets: [] }, linked_assays: [])
      end

      def back_to_index
        index
        render action: 'index'
      end

      # overides the after_filter callback from application_controller,
      # as the behaviour needs to be slightly different (based on Sturat's code)
      def log_event
        action = action_name.downcase
        return unless %w[register update batch_register].include? action

        User.with_current_user current_user do
          newly_created.each do |seek|
            ActivityLog.create(action: 'create',
                               culprit: current_user,
                               controller_name: controller_name,
                               activity_loggable: seek,
                               data: seek.title,
                               user_agent: request.env['HTTP_USER_AGENT'],
                               referenced: @openbis_endpoint)
          end
        end
      end
    end
  end
end
