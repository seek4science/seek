class StudiesController < ApplicationController

  before_filter :login_required

  before_filter :set_no_layout, :only => [ :new_investigation_redbox,:new_assay ]
  before_filter :is_user_admin_auth, :only=>[:destroy]
  before_filter :is_project_member,:only=>[:create,:new]

  protect_from_forgery :except=>[:create_investigation,:create_assay]

  def index
    
    @studies=Study.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @studys.to_xml}
    end
  end

  def new
    @study = Study.new
    @study.assays << Assay.find(params[:assay_id]) if params[:assay_id]
    
    respond_to do |format|
      format.html
    end
  end

  def edit
    @study=Study.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml=>@study.to_xml }
    end
  end

  # DELETE /study/1
  # DELETE /study/1.xml
  def destroy
    @study = Study.find(params[:id])
    @study.destroy

    respond_to do |format|
      format.html { redirect_to(studies_url) }
      format.xml  { head :ok }
    end
  end

  
  def update
    @study=Study.find(params[:id])

    respond_to do |format|
      if @study.update_attributes(params[:study])
        flash[:notice] = 'Study was successfully updated.'
        format.html { redirect_to(@study) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @study=Study.find(params[:id])
    respond_to do |format|
      format.html
      format.xml {render :xml=>@study.to_xml }
    end

  end

  def new_investigation_redbox
    project=Project.find(params[:project_id])
    @investigation=Investigation.new
    @investigation.project=project

    respond_to do |format|
      format.js 
    end
  end

  def create
    @study = Study.new(params[:study])

    respond_to do |format|
      if @study.save
        format.html { redirect_to(@study) }
        format.xml { render :xml => @study, :status => :created, :location => @study }
      else
        format.html {render :action=>"new"}
        format.xml  { render :xml => @study.errors, :status => :unprocessable_entity }
      end
    end

  end

  def create_investigation    
    title=params[:title]
    project_id=params[:project_id]
    project=Project.find(project_id)

    raise Exception.new("Person not a member of the project") if !current_user.person.projects.include?(project)
    investigation=Investigation.new(:title=>title,:project=>project)
    
    respond_to do |format|
      if investigation.save
        format.json { render :json=>{:status=>200,:new_investigation=>[investigation.id,investigation.title]} }
      else
        format.json { render :json=>{:status=>406,:error_messages=>investigation.errors.full_messages }}
      end
    end
  end



  def investigation_selected_ajax
    if params[:investigation_id] && params[:investigation_id]!="0"
      investigation=Investigation.find(params[:investigation_id])
      render :partial=>"assay_list",:locals=>{:investigation=>investigation}
    else
      render :partial=>"assay_list",:locals=>{:investigation=>nil}
    end
  end

  def project_selected_ajax

    if params[:project_id] && params[:project_id]!=0
      investigations=Investigation.find(:all,:conditions=>{:project_id=>params[:project_id]})
    end

    investigations||=[]

    render :update do |page|
      page.replace_html "investigation_collection",:partial=>"investigation_list",:locals=>{:investigations=>investigations,:project_id=>params[:project_id]}
    end

  end

  
end
