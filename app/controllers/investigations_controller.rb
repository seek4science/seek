class InvestigationsController < ApplicationController

  include DotGenerator
  include IndexPager

  before_filter :find_assets, :only=>[:index]
  before_filter :make_investigation_and_auth,:only=>[:create]
  before_filter :find_and_auth,:only=>[:edit, :update, :destroy]

  def new_object_based_on_existing_one
    @existing_investigation =  Investigation.find(params[:id])
    @investigation = @existing_investigation.clone_with_associations
    render :action=>"new"
  end

  def destroy    
    @investigation.destroy

    respond_to do |format|
      format.html { redirect_to(investigations_url) }
      format.xml  { head :ok }
    end
  end

  def show
    @investigation=Investigation.find(params[:id])
    @investigation.create_from_asset = params[:create_from_asset]
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@investigation,params[:deep]=='true')}
      format.dot { render :text=>to_dot(@investigation,params[:deep]=='true')}
      format.png { render :text=>to_png(@investigation,params[:deep]=='true')}
    end
  end

  def create
    @investigation.policy.set_attributes_with_sharing params[:sharing], @investigation.project
    respond_to do |format|
      if @investigation.save
        flash[:notice] = 'The Investigation was successfully created.'
        if @investigation.create_from_asset=="true"
           flash.now[:notice] << "<br/> Now you can create new study for your assay by clicking 'add a study' button"
        end
        format.html { redirect_to investigation_path(:id=>@investigation,:create_from_asset=>@investigation.create_from_asset) }
        format.xml { render :xml => @investigation, :status => :created, :location => @investigation }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @investigation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @investigation=Investigation.new
    @investigation.create_from_asset = params[:create_from_asset]
    respond_to do |format|
      format.html
      format.xml { render :xml=>@investigation}
    end
  end

  def edit
    @investigation=Investigation.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @investigation=Investigation.find(params[:id])

    @investigation.attributes = params[:investigation]

    if params[:sharing]
      @investigation.policy_or_default
      @investigation.policy.set_attributes_with_sharing params[:sharing], @investigation.project
    end

    respond_to do |format|
      if @investigation.save
        flash[:notice] = 'Investigation was successfully updated.'
        format.html { redirect_to(@investigation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @investigation.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def make_investigation_and_auth
    @investigation=Investigation.new(params[:investigation])
    unless current_user.person.projects.include?(@investigation.project)
      respond_to do |format|
        flash[:error] = "You cannot create a investigation for a project you are not a member of."
        format.html { redirect_to investigations_path }
      end
      return false
    end
  end
  
end
