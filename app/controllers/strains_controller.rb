class StrainsController < ApplicationController
  before_filter :login_required
  before_filter :get_strains,:only=>:show_existing_strains
  before_filter :get_strain, :only =>:show_existing_strain

  def show_existing_strains
    element=params[:element]    
    render :update do |page|
      page.replace_html element,:partial=>"strains/existing_strains",:object=>@strains,:locals=>{:organism=>@organism}
    end
  end

  def show_existing_strain
    render :update do |page|
      page.replace_html "existing_strain",:partial=>"strains/existing_strain",:object=>@strain
    end
  end

  def get_strains
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      @strains=@organism.strains
    end
  end

  def get_strain
    if params[:id]
      @strain=Strain.find_by_id(params[:id])
    end
  end
  def show
    @strain=Strain.find(params[:id])
    respond_to do |format|
      format.xml
    end
  end
  
  def index
    @strains=Strain.all
    respond_to do |format|
      format.xml
    end
  end

end
