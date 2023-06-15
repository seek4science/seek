class CustomMetadataTypesController < ApplicationController
  respond_to :json

  before_action :find_custom_metadata_type, only: [:show]

  # generated for form, to display fields for selected metadata type
  def form_fields
    id = params[:id]
    respond_to do |format|
      if id.blank?
        format.html { render html: '' }
      else
        cm = CustomMetadataType.find(id)
        resource = safe_class_lookup(cm.supported_type).new
        resource.custom_metadata = CustomMetadata.new(custom_metadata_type: cm)
        format.html do
          render partial: 'custom_metadata/custom_metadata_fields',
                 locals: { custom_metadata_type: cm, resource: resource }
        end
      end
    end
  end

  def show
     respond_to do |format|
        format.json {render json: @custom_metadata_type}
      end
  end

  private

  def find_custom_metadata_type
    @custom_metadata_type = CustomMetadataType.find(params[:id])
  end

end
