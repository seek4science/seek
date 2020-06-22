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
        base.before_action :endpoint
        base.before_action :project
        base.before_action :project_member?

        base.before_action :check_entity, only: %i[show edit register update refresh show_dataset_files]
        base.before_action :prepare_asset, only: %i[show edit register update refresh show_dataset_files]
        base.before_action :already_registered?, only: [:register]
        base.before_action :sync_options, only: %i[register update]
        base.before_action :batch_parameters, only: [:batch_register]
        base.before_action :batch_sync_options, only: %i[batch_register]
      end

      def index
        entity_type
        entity_types
        entities
      end

      def edit
        seek_entity
        zamples_linked_to(@seek_entity)
        datasets_linked_to(@seek_entity)
      end

      def refresh
        seek_util.sync_asset_content(@asset)

        flash[:error] = "OBis synchronization failed: #{@asset.err_msg}" if @asset.failed?
        flash[:notice] = 'Updated OpenBis content' if @asset.synchronized?
        redirect_to @asset.seek_entity
      end

      def register
        reg_info = do_entity_registration(@asset, seek_params, @sync_options, current_person)

        @newly_created = reg_info.created

        unless reg_info.primary
          flash[:error] = "Could not register OpenBIS #{@asset.entity.type_name} #{@asset.perm_id}"
          flash_issues(reg_info.issues)
          return redirect_to action: :edit
        end

        @seek_entity = reg_info.primary
        msg = "Registered OpenBIS #{@asset.entity.type_name} #{@asset.perm_id} as #{@seek_entity.class}"
        msg += ' with some issues' unless reg_info.issues.empty?
        flash[:notice] = msg
        flash_issues(reg_info.issues)

        redirect_to @seek_entity
      end

      def update
        return redirect_to action: :edit unless @asset.seek_entity

        @asset.sync_options = @sync_options
        # or maybe we should not update, but that is what the user saw on the screen
        @asset.content = @entity

        # separate saving of external_asset as the save on parent does not fails
        # if the child was not saved correctly, also currently the Seek object is not actually saved
        unless @asset.save
          flash[:error] = "Could not update OpenBIS #{@asset.entity.type_name} #{@asset.perm_id}"
          flash_issues(@asset.errors)
          return redirect_to action: :edit
        end

        @seek_entity = @asset.seek_entity
        reg_info = seek_util.follow_dependent_from_seek(@seek_entity)

        msg = "Updated registration of #{@asset.entity.type_name} #{@asset.perm_id}"
        msg += ' with issues' unless reg_info.issues.empty?
        flash[:notice] = msg
        flash_issues(reg_info.issues)
        redirect_to @seek_entity
      end

      def batch_register
        status = do_batch_register(@batch_ids)
        @newly_created = status[:created]

        msg = if status[:failed].empty?
                "Registered all #{status[:registered].size} OpenBIS entities"
              else
                "Registered #{status[:registered].size} OpenBIS entities but #{status[:failed].size} failed"
              end
        flash[:notice] = msg
        flash_issues(status[:issues])

        back_to_index
      end

      def do_batch_register(entity_ids)
        registered = []
        failed = []
        batch_info = Seek::Openbis::RegistrationInfo.new

        entity_ids.each do |id|
          entity(id)
          prepare_asset

          # params must be new for each call
          # syn_options cloned so they won't be reused
          reg_info = do_entity_registration(@asset, seek_params_for_batch, @sync_options.clone, current_person)
          registered << id if reg_info.primary
          failed << id unless reg_info.primary
          batch_info.merge reg_info
        end

        { registered: registered, failed: failed, issues: batch_info.issues, created: batch_info.created }
      end

      def do_entity_registration(asset, seek_params, sync_options, creator)
        reg_status = valid_asset_for_registration(asset, sync_options)

        return reg_status unless reg_status.issues.empty?

        seek_entity = create_seek_object_for_obis(seek_params, creator, asset)

        if seek_entity.save
          reg_status.primary = seek_entity
          reg_status.merge seek_util.follow_dependent_from_seek(seek_entity)
        else
          reg_status.add_issues seek_entity.errors.full_messages
        end

        reg_status
      end

      def valid_asset_for_registration(asset, sync_options)
        reg_status = Seek::Openbis::RegistrationInfo.new

        if asset.seek_entity
          reg_status.add_issues 'Already registered in SEEK'
          return reg_status
        end

        asset.sync_options = sync_options

        # separate testing of external_asset as the save on parent does not fails if the child was not saved correctly
        reg_status.add_issues asset.errors.full_messages unless asset.valid?
        reg_status
      end

      def check_entity
        entity
      rescue => e
        msg = seek_util.extract_err_message(e)
        flash[:error] = "Cannot access OBis: #{msg}"
        redirect_back fallback_location: @project
      end

      def newly_created
        @newly_created ||= []
      end

      def endpoint
        @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
      end

      def project
        @project = @openbis_endpoint.project
      end

      def batch_parameters
        @batch_ids = params[:batch_ids] || []
        @seek_parent_id = params[:seek_parent]

        if @batch_ids.empty?
          flash[:error] = 'Select entities first'
          return back_to_index
        end

        unless @seek_parent_id
          flash[:error] = 'Select parent for new elements'
          return back_to_index
        end
      end

      def zamples_linked_to(seek)
        assays = []
        assays = seek.assays if seek.is_a? Study

        @zamples_linked_to = assays
                             .select { |a| a.external_asset.is_a?(OpenbisExternalAsset) }
                             .map { |a| a.external_asset.external_id }
      end

      def datasets_linked_to(seek)
        data_files = []
        data_files = seek.related_data_files if seek.is_a? Study
        data_files = seek.data_files if seek.is_a? Assay

        @datasets_linked_to = data_files
                              .select { |df| df.external_asset.is_a?(OpenbisExternalAsset) }
                              .map { |df| df.external_asset.external_id }
      end

      def project_member?
        return true if @project.has_member?(User.current_user)
        error("Must be a member of the #{t('project').downcase}", 'No permission')
        false
      end

      def already_registered?
        if @asset.seek_entity
          flash[:error] = 'OpenBIS entity already registered in Seek'
          redirect_to @asset.seek_entity
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

      def sync_options
        @sync_options = parse_sync_options
      end

      def batch_sync_options
        sync_options
        @sync_options[:link_datasets] = '1' if @sync_options[:link_dependent] == '1'
        @sync_options[:link_assays] = '1' if @sync_options[:link_dependent] == '1'
        @sync_options.delete(:link_dependent)
      end

      def parse_sync_options(hash = nil)
        hash ||= params
        hash.fetch(:sync_options, {}).permit(:link_datasets, :link_assays, :link_dependent, :new_arrivals,
                                             { linked_datasets: [] }, linked_assays: [])
      end

      def back_to_index
        index
        render action: 'index'
      end

      # overides the after_action callback from application_controller,
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
