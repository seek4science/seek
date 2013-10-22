class TechnologyTypesController < ApplicationController
  before_filter :find_requested_item, :only=>[:show]

  def show
    respond_to do |format|
      format.html
      format.xml
    end    
  end
  
  def index 
    @technology_types = TechnologyType.all
    respond_to do |format|
      format.xml
    end
  end
  
end