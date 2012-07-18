class StrainsController < ApplicationController
  include IndexPager
  include Seek::AnnotationCommon
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]

  before_filter :get_strains,:only=>[:show_existing_strains, :existing_strains_for_assay_organism]
  before_filter :get_strain, :only =>:show_existing_strain
  include Seek::Publishing

  def new
    @strain = Strain.new()
  end


  def create
    @strain = BiosamplesController.new().new_strain(params[:strain])
    @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    update_annotations @strain
    if @strain.save
      deliver_request_publish_approval params[:sharing], @strain
      respond_to do |format|
        flash[:notice] = 'Strain was successfully created.'
        format.html { redirect_to(@strain) }
        format.xml { render :xml => @strain, :status => :created, :location => @strain }
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml { render :xml => @strain.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    update_annotations @strain
    if params[:sharing]
      @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    end
    @strain.attributes = params[:strain]
    if @strain.save
      deliver_request_publish_approval params[:sharing], @strain
      respond_to do |format|
        flash[:notice] = 'Strain was successfully updated.'
        format.html { redirect_to(@strain) }
        format.xml { render :xml => @strain, :status => :created, :location => @strain }
      end
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml { render :xml => @strain.errors, :status => :unprocessable_entity }
      end
    end
  end


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

  def new_strain_form
    @strain = Strain.find_by_id(params[:id]) || Strain.new
    render :update do |page|
      page.visual_effect :fade, 'existing_strains', :duration => 0.25
      page.remove 'strain_form'
      page.insert_html :bottom, "create_new_strain",:partial=>"strains/form",:locals=>{:strain => @strain, :action => params[:status], :organism_id => params[:organism_id]}
    end
  end

  def existing_strains_for_assay_organism
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains_for_assay_organism', :partial=>"strains/existing_strains_for_assay_organism",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'existing_strains_for_assay_organism',:text=>""
      end
    end
  end

  def get_strains
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      strains=@organism.try(:strains)
      @strains = strains ? strains.reject{|s| s.is_dummy? || s.id == params[:strain_id].to_i} : strains
    end
  end

  def get_strain
    if params[:id]
      @strain=Strain.find_by_id(params[:id])
    end
  end

  def destroy
    respond_to do |format|
      if @strain.destroy
        format.html { redirect_to(strains_path) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the strain."
        format.html { render :action=>"show" }
        format.xml { render :xml => @strain.errors, :status => :unprocessable_entity }
      end
    end
  end
end
