class TechnologyTypesController < ApplicationController
  
  before_filter :check_allowed_to_manage_types, :except=>[:show,:index]
  
  def show
    @technology_type = TechnologyType.find(params[:id])
    
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