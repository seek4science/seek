class InvestigationsController < ApplicationController

  include DotGenerator

  before_filter :login_required
  before_filter :is_project_member,:only=>[:create,:new]
  before_filter :make_investigation_and_auth,:only=>[:create]
  before_filter :investigation_auth_project,:only=>[:edit,:update]
  before_filter :delete_allowed,:only=>[:destroy]


  def index
    @investigations=Investigation.find(:all, :include=>:studies, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>'updated_at DESC')
    @investigations=Investigation.paginate :page=>params[:page]

    respond_to do |format|
      format.html
      format.xml
    end
    
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
    deep=params[:deep]
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@investigation,deep)}
      format.dot { render :text=>to_dot(@investigation,deep)}
      format.png { render :text=>to_png(@investigation,deep)}
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
        format.html { redirect_to studies_path }
      end
      return false
    end
  end

  def investigation_auth_project
    @investigation=Investigation.find(params[:id])
    unless @investigation.can_edit?(current_user)
      flash[:error] = "You cannot edit an Investigation for a project you are not a member."
      redirect_to @investigation
    end
  end

  def delete_allowed
    @investigation=Investigation.find(params[:id])
    unless @investigation.can_delete?(current_user)
      respond_to do |format|
        flash[:error] = "You cannot delete an Investigation related to a project or which you are not a member, or that has studies associated"
        format.html { redirect_to investigations_path }
      end
      return false
    end
  end
  
end
