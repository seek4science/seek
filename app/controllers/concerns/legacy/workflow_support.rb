module Legacy
  module WorkflowSupport
    extend ActiveSupport::Concern

    included do
      before_action :login_required, only: [:create_content_blob, :create_ro_crate]
      before_action :legacy_set_workflow, only: [:create_content_blob, :create_ro_crate]
    end

    def create_ro_crate
      @crate_builder = Legacy::WorkflowCrateBuilder.new(legacy_ro_crate_params)
      @crate_builder.workflow_class = @workflow.workflow_class
      blob_params = @crate_builder.build
      @workflow.build_content_blob(blob_params)

      respond_to do |format|
        if blob_params && @workflow.content_blob.save && extract_metadata
          format.html { render :provide_metadata }
        else
          format.html { render action: @workflow.persisted? ? :new_version : :new, status: :unprocessable_entity }
        end
      end
    end

    def create_content_blob
      respond_to do |format|
        if handle_upload_data(@workflow.persisted?) && @workflow.content_blob.save && extract_metadata
          format.html { render :provide_metadata }
        else
          format.html { render action: @workflow.persisted? ? :new_version : :new, status: :unprocessable_entity }
        end
      end
    end

    private

    def legacy_ro_crate_params
      params.require(:ro_crate).permit({ workflow: [:data, :data_url, :make_local_copy] },
                                       { abstract_cwl: [:data, :data_url, :make_local_copy] },
                                       { diagram: [:data, :data_url, :make_local_copy] })
    end

    def legacy_set_workflow
      if params[:workflow_id]
        @workflow = Workflow.find(params[:workflow_id])
      else
        @workflow = Workflow.new(workflow_class_id: params[:workflow_class_id])
      end
    end

    def extract_metadata
      begin
        extractor = @workflow.extractor
        retrieve_content @workflow.content_blob # Hack
        @metadata = extractor.metadata
        @warnings ||= @metadata.delete(:warnings) || []
        @errors ||= @metadata.delete(:errors) || []
        @workflow.assign_attributes(@metadata)
      rescue StandardError => e
        raise e unless Rails.env.production?
        Seek::Errors::ExceptionForwarder.send_notification(e, data: {
            message: "Problem attempting to extract metadata for content blob #{params[:content_blob_id]}" })
        flash[:error] = 'An unexpected error occurred whilst extracting workflow metadata.'
        return false
      end

      true
    end
  end
end