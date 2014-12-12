module Seek
  module DestroyHandling
    #common controller methods for destroy
    def destroy
      asset = determine_asset_from_controller
      respond_to do |format|
        respond_to_destruction(asset, format)
      end
    end

    def respond_to_destruction(asset, format)
      redirect_location_on_success = url_for :action => :index
      can_delete = !asset.respond_to?(:can_delete?) || asset.can_delete?
      if can_delete && asset.destroy
        format.html { redirect_to(redirect_location_on_success) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the #{controller_name.singularize}"
        format.html { render :action => "show" }
        format.xml { render :xml => asset.errors, :status => :unprocessable_entity }
      end
    end

    def determine_asset_from_controller
      name = self.controller_name.singularize
      eval("@#{name}")
    end

  end
end