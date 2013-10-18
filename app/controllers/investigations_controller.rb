class InvestigationsController < ApplicationController

  include DotGenerator
  include IndexPager

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_auth,:only=>[:edit, :update, :destroy, :show]

  include Seek::Publishing
  include Seek::BreadCrumbs

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
    @investigation=Investigation.new(params[:investigation])
    @investigation.policy.set_attributes_with_sharing params[:sharing], @investigation.projects

    if @investigation.save
      deliver_request_publish_approval params[:sharing], @investigation
       if @investigation.new_link_from_study=="true"
          render :partial => "assets/back_to_singleselect_parent",:locals => {:child=>@investigation,:parent=>"study"}
       else
        respond_to do |format|
          flash[:notice] = 'The Investigation was successfully created.'
          if @investigation.create_from_asset=="true"
             flash.now[:notice] << "<br/> Now you can create new study for your assay by clicking 'add a study' button"
            format.html { redirect_to investigation_path(:id=>@investigation,:create_from_asset=>@investigation.create_from_asset) }
          else
            format.html { redirect_to investigation_path(@investigation) }
            format.xml { render :xml => @investigation, :status => :created, :location => @investigation }
          end
        end
       end
    else
      respond_to do |format|
      format.html { render :action => "new" }
      format.xml { render :xml => @investigation.errors, :status => :unprocessable_entity }
    end
    end

  end

  def new
    @investigation=Investigation.new
    @investigation.create_from_asset = params[:create_from_asset]
    @investigation.new_link_from_study = params[:new_link_from_study]

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
      @investigation.policy.set_attributes_with_sharing params[:sharing], @investigation.projects
    end

    respond_to do |format|
      if @investigation.save
        deliver_request_publish_approval params[:sharing], @investigation
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
  
end
