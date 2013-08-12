class AssayTypesController < ApplicationController

  def show
    @assay_type = AssayType.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end
  
  def index
    @assay_types=AssayType.all
    respond_to do |format|
      format.xml
    end
  end
  

  
end