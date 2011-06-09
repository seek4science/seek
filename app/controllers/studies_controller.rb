class StudiesController < ApplicationController

  include DotGenerator
  include IndexPager

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_auth, :only=>[:edit, :update, :destroy, :show]

  before_filter :check_assays_are_not_already_associated_with_another_study,:only=>[:create,:update]
  

  def new_object_based_on_existing_one
    @existing_study =  Study.find(params[:id])
    @study = @existing_study.clone_with_associations

    unless @study.investigation.can_view?
       @study.investigation = nil
      flash[:notice] = 'The investigation of the existing study cannot be viewed, please specify your own investigation!'
    end

    render :action=>"new"
  end

  def new
    @study = Study.new
    investigation = nil
    investigation = Investigation.find(params[:investigation_id]) if params[:investigation_id]
    
    if investigation
      if investigation.can_edit?
        @study.investigation = investigation
      else
        flash.now[:error] = "You do now have permission to associate the new study with the investigation '#{investigation.title}'."
      end
    end
    
    respond_to do |format|
      format.html
    end
  end

  def edit
    @study=Study.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end

  # DELETE /study/1
  # DELETE /study/1.xml
  def destroy
    
    @study.destroy

    respond_to do |format|
      format.html { redirect_to(studies_url) }
      format.xml  { head :ok }
    end
  end

  
  def update
    @study=Study.find(params[:id])

    @study.attributes = params[:study]

    if params[:sharing]
      @study.policy_or_default
      @study.policy.set_attributes_with_sharing params[:sharing], @study.project
    end

    respond_to do |format|
      if @study.save
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
      format.xml
      format.svg { render :text=>to_svg(@study.investigation,params[:deep]=='true',@study)}
      format.dot { render :text=>to_dot(@study.investigation,params[:deep]=='true',@study)}
      format.png { render :text=>to_png(@study.investigation,params[:deep]=='true',@study)}
    end

  end

  def create
    @study = Study.new(params[:study])

    @study.policy.set_attributes_with_sharing params[:sharing], @study.project

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
end
