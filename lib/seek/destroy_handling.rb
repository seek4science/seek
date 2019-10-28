module Seek
  module DestroyHandling
    # common controller methods for destroy
    def destroy
      asset = determine_asset_from_controller
      respond_to do |format|
        respond_to_destruction(asset, format)
      end
    end

    def respond_to_destruction(asset, format)
      can_delete = !asset.respond_to?(:can_delete?) || asset.can_delete?
      asset_type_text = t(asset.class.name.underscore)
      if can_delete && asset.destroy
        flash[:notice] = "#{asset_type_text} was successfully deleted."
        format.html { redirect_to(redirect_location_on_success) }
        format.xml { head :ok }
        format.json { render json: { status: :ok }, status: :ok }
      else
        flash.now[:error] = "Unable to delete the #{controller_name.singularize}"
        format.html { render action: 'show' }
        format.xml { render xml: asset.errors, status: :unprocessable_entity }
        format.json { render json: { "title": asset.errors, status: :unprocessable_entity }, status: :unprocessable_entity }
      end
    end

    def destroy_version
      asset = determine_asset_from_controller
      if Seek::Config.delete_asset_version_enabled
        asset.destroy_version params[:version]
        flash[:notice] = "Version #{params[:version]} was deleted!"
      else
        flash[:error] = "Deleting a version of #{asset.class.name.underscore.humanize} is not enabled!"
      end
      respond_to do |format|
        format.html { redirect_to(polymorphic_path(asset)) }
        format.xml { head :ok }
      end
    end

    def redirect_location_on_success
      if params[:return_to] && params[:return_to] == 'my_items'
        items_person_path(current_person)
      else
        url_for action: :index
      end
    end
  end
end
