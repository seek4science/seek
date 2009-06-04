class InvestigationsController < ApplicationController

  before_filter :login_required
  before_filter :is_project_member,:only=>[:create,:new]
  before_filter :make_investigation_and_auth,:only=>[:create]
  #before_filter :investigation_auth_project,:only=>[:edit,:update]
  


  def index
    @investigations=Investigation.find(:all, :include=>:studies, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>'updated_at DESC')

    respond_to do |format|
      format.html
      format.xml {render :xml=>@investigations}
    end
    
  end

  def show
    @investigation=Investigation.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=> @investigation, :include=>@investigation.studies }
    end

  end

  def create
    respond_to do |format|      
      if @investigation.save
        flash[:notice] = 'The Investigation was successfully created.'
        format.html { redirect_to(@investigation) }
        format.xml  { render :xml => @investigation, :status => :created, :location => @investigation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @investigation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @investigation=Investigation.new

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

    respond_to do |format|
      if @investigation.update_attributes(params[:investigation])
        flash[:notice] = 'Study was successfully updated.'
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
          format.html { redirect_to studies_path }
        end
        return false
    end
  end
  
end
