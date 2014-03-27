class StrainsController < ApplicationController
  include IndexPager
  include Seek::AnnotationCommon

  before_filter :organisms_enabled?
  before_filter :find_assets, :only => [:index]
  before_filter :find_and_authorize_requested_item, :only => [:show, :edit, :update, :destroy]

  before_filter :get_strains_for_organism,:only=>[:existing_strains_for_assay_organism]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  def new
    @strain = Strain.new()
  end

  def create
    @strain = BiosamplesController.new().new_strain(params[:strain])
    @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    update_annotations @strain
    if @strain.save
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

  def show
    respond_to do |format|
      format.rdf { render :template=>'rdf/show'}
      format.xml
      format.html
    end
  end

  def update
    update_annotations @strain
    if params[:sharing]
      @strain.policy.set_attributes_with_sharing params[:sharing], @strain.projects
    end
    @strain.attributes = params[:strain]
    if @strain.save
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

  def existing_strains_for_assay_organism
    if User.current_user
      #restrict strains to those of that persons project
      projects = User.current_user.person.projects
      @strains = @strains.select{|s| !(s.projects & projects).empty?}
    end
    render :update do |page|
      if @strains && @organism
        page.replace_html 'existing_strains_for_assay_organism', :partial=>"strains/existing_strains_for_assay_organism",:object=>@strains,:locals=>{:organism=>@organism}
      else
        page.insert_html :bottom, 'existing_strains_for_assay_organism',:text=>""
      end
    end
  end

  def get_strains_for_organism
    if params[:organism_id]
      @organism=Organism.find_by_id(params[:organism_id])
      strains=@organism.try(:strains)
      @strains = strains ? strains.reject{|s| s.is_dummy? || s.id == params[:strain_id].to_i}.select(&:can_view?) : strains
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
