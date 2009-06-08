class StudiesController < ApplicationController

  before_filter :login_required
    
  before_filter :is_project_member,:only=>[:create,:new]
  before_filter :check_assays_are_not_already_associated_with_another_study,:only=>[:create,:update]
  before_filter :study_auth_project,:only=>[:edit,:update]
  before_filter :delete_allowed,:only=>[:destroy]

  def index
    
    @studies=Study.find(:all,:page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>'updated_at DESC')

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


  def investigation_selected_ajax
    if params[:investigation_id] && params[:investigation_id]!="0"
      investigation=Investigation.find(params[:investigation_id])
      render :partial=>"assay_list",:locals=>{:investigation=>investigation}
    else
      render :partial=>"assay_list",:locals=>{:investigation=>nil}
    end
  end

  def project_selected_ajax

    if params[:project_id] && params[:project_id]!="0"
      investigations=Investigation.find(:all,:conditions=>{:project_id=>params[:project_id]})
      people=Project.find(params[:project_id]).people
    end

    investigations||=[]
    people||=[]

    render :update do |page|
      page.replace_html "investigation_collection",:partial=>"studies/investigation_list",:locals=>{:investigations=>investigations,:project_id=>params[:project_id]}
      page.replace_html "person_responsible_collection",:partial=>"studies/person_responsible_list",:locals=>{:people=>people,:project_id=>params[:project_id]}
    end

  end

  def check_assays_are_not_already_associated_with_another_study
    assay_ids=params[:study][:assay_ids]
    study_id=params[:id]    
    if (assay_ids)
      valid = !assay_ids.detect do |a_id|
        a=Assay.find(a_id)
        !a.study.nil? && a.study_id.to_s!=study_id
      end
      if !valid
        unless valid
          error("Cannot add an assay already associated with a Study", "is invalid (invalid Assay)")
          return false
        end
      end
    end
  end

  def study_auth_project
    @study=Study.find(params[:id])
    unless @study.can_edit?(current_user)
      flash[:error] = "You cannot edit a Study for a project you are not a member."
      redirect_to @study
    end
  end

  def delete_allowed
    @study=Study.find(params[:id])
    unless @study.can_delete?(current_user)
      respond_to do |format|
        flash[:error] = "You cannot delete a Study related to a project or which you are not a member, or that has assays associated"
        format.html { redirect_to studies_path }
      end
      return false
    end
  end
  
end
