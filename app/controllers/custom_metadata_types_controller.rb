class CustomMetadataTypesController < ApplicationController
  # generated for form, to display fields for selected metadata type
  def form_fields
    id = params[:id]
    respond_to do |format|
      if id.blank?
        format.html { render html: '' }
      else
        cm = CustomMetadataType.find(id)
        resource = cm.supported_type.constantize.new
        resource.custom_metadata = CustomMetadata.new(custom_metadata_type: cm)
        format.html do
          render partial: 'custom_metadata/custom_metadata_fields',
                 locals: { custom_metadata_type: cm, resource: resource }
        end
      end
    end
  end
end
