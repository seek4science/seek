class AssayTypesController < ApplicationController

  before_filter :find_requested_item, :only=>[:show]

  def show
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