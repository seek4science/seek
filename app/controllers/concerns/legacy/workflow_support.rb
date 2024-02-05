module Legacy
  module WorkflowSupport
    extend ActiveSupport::Concern

    included do
      before_action :legacy_login_required, only: [:create_content_blob, :create_ro_crate]
      before_action :legacy_set_workflow, only: [:create_content_blob, :create_ro_crate]
    end

    # Creating a Workflow from individual files
    def create_ro_crate
      @crate_builder = Legacy::WorkflowCrateBuilder.new(legacy_ro_crate_params)
      @workflow.workflow_class = @crate_builder.workflow_class = WorkflowClass.find_by_id(params[:workflow_class_id])
      blob_params = @crate_builder.build
      @content_blob = ContentBlob.new(blob_params)

      respond_to do |format|
        if blob_params && @content_blob.save && extract_metadata(@content_blob)
          format.html { render :provide_metadata }
        else
          format.html { render action: @workflow.persisted? ? :new_version : :new, status: :unprocessable_entity }
        end
      end
    end

    # Creating a Workflow from a user-provided RO-Crate
    def create_content_blob
      workflow = @workflow
      @workflow = Workflow.new(workflow_class: workflow.workflow_class)
      respond_to do |format|
        if handle_upload_data && @workflow.content_blob.save
          @content_blob = @workflow.content_blob
          @workflow = workflow
          if extract_metadata(@content_blob)
            format.html { render :provide_metadata }
          else
            format.html { render action: @workflow.persisted? ? :new_version : :new, status: :unprocessable_entity }
          end
        else
          @workflow = workflow
          format.html { render action: @workflow.persisted? ? :new_version : :new, status: :unprocessable_entity }
        end
      end
    end

    private

    def legacy_ro_crate_params
      l_params = params.require(:ro_crate).permit({ workflow: [:data, :data_url, :make_local_copy]},
                                       { abstract_cwl: [:data, :data_url, :make_local_copy] },
                                       { diagram: [:data, :data_url, :make_local_copy] })
      l_params[:workflow][:project_ids] = params.dig(:workflow, :project_ids) || []
      l_params
    end

    def legacy_set_workflow
      if params[:workflow_id]
        @workflow = Workflow.find(params[:workflow_id])
      else
        @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
      end
    end

    # This is deliberately named differently from `login_required`, or it will overwrite the
    # `before_action :login_required, only: [...]` in WorkflowsController.
    def legacy_login_required
      login_required
    end

    def legacy_handle_ro_crate_post(new_version = false)
      @workflow = Workflow.new unless new_version
      extractor = Seek::WorkflowExtractors::ROCrate.new(params[:ro_crate])

      @workflow.assign_attributes(extractor.metadata.except(:errors, :warnings))
      @workflow.assign_attributes(workflow_params)
      crate_upload = params[:ro_crate]
      old_content_blob = new_version ? @workflow.content_blob : nil
      version = new_version ? @workflow.version + 1 : 1
      @workflow.build_content_blob(tmp_io_object: crate_upload,
                                   original_filename: crate_upload.original_filename,
                                   content_type: crate_upload.content_type,
                                   asset_version: version)
      if old_content_blob
        old_content_blob.update_column(:asset_id, @workflow.id)
      end

      if new_version
        success = @workflow.save_as_new_version(params[:revision_comments])
      else
        create_asset(@workflow)
        success = @workflow.save
      end

      if success
        render json: @workflow, include: json_api_include_param
      else
        render json: json_api_errors(@workflow), status: :unprocessable_entity
      end
    end

    def extract_metadata(content_blob)
      begin
        retrieve_content content_blob # Hack
        # Another hack to get around the fact that if we associate the content_blob with @workflow, it will automatically
        # unlink any existing content_blob, which breaks things when creating a new version:
        extractor = Workflow.new(content_blob: content_blob, workflow_class: @workflow.workflow_class).extractor
        @metadata = extractor.metadata
        @workflow.provide_metadata(@metadata)
      rescue StandardError => e
        raise e unless Rails.env.production?
        Seek::Errors::ExceptionForwarder.send_notification(e, data: {
            message: "Problem attempting to extract metadata for content blob #{params[:content_blob_id]}" })
        flash[:error] = 'An unexpected error occurred whilst extracting workflow metadata.'
        return false
      end

      true
    end

    def retrieve_content(blob)
      unless blob.file_exists?
        blob.remote_content_fetch_task&.cancel
        blob.retrieve
      end
    end
  end
end