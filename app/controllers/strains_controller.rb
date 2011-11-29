class StrainsController < ApplicationController
  before_filter :login_required
  before_filter :get_strains,:only=>[:show_existing_strains, :existing_strains_for_select]
  before_filter :get_strain, :only =>[:show_existing_strain, :strain_detail]

  def show_existing_strains
    render :update do |page|
      if @strains && @organism
        page.visual_effect :fade, 'strain_form', :duration => 0.25
        page.remove 'existing_strains'
        page.insert_html :bottom, 'create_based_on_existing_strain', :partial=>"strains/existing_strains",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'create_based_on_existing_strain',:text=>""
      end
    end
  end

  def show_existing_strain
    render :update do |page|
      page.remove 'strain_form'
      page.insert_html :bottom, "create_based_on_existing_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :action => params[:status], :organism_id => params[:organism_id]}
    end
  end

  def new_strain
    @strain = Strain.find_by_id(params[:id]) || Strain.new
    render :update do |page|
      page.visual_effect :fade, 'existing_strains', :duration => 0.25
      page.remove 'strain_form'
      page.insert_html :bottom, "create_new_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :action => params[:status], :organism_id => params[:organism_id]}
    end
  end

  def strain_detail
    render :update do |page|
      page.replace_html "strain_detail",:partial=>"strains/strain_detail",:locals=>{:strain => @strain}
      page.visual_effect :appear, 'strain_detail'
    end
  end

  def existing_strains_for_select
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains_for_select', :partial=>"strains/existing_strains_for_select",:object=>@strains,:locals=>{:organism=>@organism}
        page.visual_effect :appear, 'existing_strains_for_select'
      else
        page.insert_html :bottom, 'existing_strains_for_select',:text=>""
      end
    end
  end

  def get_strains
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      @strains=@organism.try(:strains).reject{|s| s.title == 'default' || s.id == params[:strain_id].to_i}
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
