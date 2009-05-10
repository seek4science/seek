class AssayTypesController < ApplicationController

  before_filter :login_required

  def show
    @assay_type = AssayType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=>@assay_type}
    end

  end
  
end
