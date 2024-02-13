class ExtendedMetadataTypesController < ApplicationController


  before_action :is_user_admin_auth, except: [:form_fields, :show]
  before_action :find_requested_item, only: [:administer_update, :show]


  # generated for form, to display fields for selected metadata type
  def form_fields
    id = params[:id]
    parent_resource = params[:parentResource] unless params[:parentResource]&.empty?
    respond_to do |format|
      if id.blank?
        format.html { render html: '' }
      else
        cm = ExtendedMetadataType.find(id)
        resource = safe_class_lookup(cm.supported_type).new
        resource.extended_metadata = ExtendedMetadata.new(extended_metadata_type: cm)
        format.html do
          render partial: 'extended_metadata/extended_metadata_fields',
                 locals: { extended_metadata_type: cm, resource: resource, parent_resource: parent_resource}
        end
      end
    end
  end

  def show
     respond_to do |format|
        format.json {render json: @extended_metadata_type}
      end
  end

  def administer_update
    @extended_metadata_type.update(extended_metadata_type_params)
    unless @extended_metadata_type.save
      flash[:error] = "Unable to save"
    end
    respond_to do |format|
      format.html { redirect_to administer_extended_metadata_types_path }
    end
  end

  def administer
    @extended_metadata_types = ExtendedMetadataType.order(:supported_type)
    respond_to do |format|
      format.html
    end
  end

  private

  def extended_metadata_type_params
    params.require(:extended_metadata_type).permit(:title, :enabled)
  end

end
