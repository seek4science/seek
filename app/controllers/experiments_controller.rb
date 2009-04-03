class ExperimentsController < ApplicationController  
  
  before_filter :login_required

  before_filter :set_no_layout, :only => [ :new_topic,:new_assay ]
  before_filter :is_user_admin_auth, :only=>[:destroy]

  protect_from_forgery :except=>[:create_topic,:create_assay]

  def index
    @experiments=Experiment.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments.to_xml}
    end
  end

  def new
    @experiment = Experiment.new
  end

  def edit
    @experiment=Experiment.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml=>@experiment.to_xml }
    end
  end

  # DELETE /experiments/1
  # DELETE /experiments/1.xml
  def destroy
    @experiment = Experiment.find(params[:id])
    @experiment.destroy

    respond_to do |format|
      format.html { redirect_to(experiments_url) }
      format.xml  { head :ok }
    end
  end

  # PUT /institutions/1
  # PUT /institutions/1.xml
  def update
    @experiment=Experiment.find(params[:id])
    

    respond_to do |format|
      if @experiment.update_attributes(params[:experiment])
        flash[:notice] = 'Experiment was successfully updated.'
        format.html { redirect_to(@experiment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @experiment=Experiment.find(params[:id])
    respond_to do |format|
      format.html
      format.xml {render :xml=>@experiment.to_xml }
    end

  end

  def new_topic
    project=Project.find(params[:project_id])
    @topic=Topic.new
    @topic.project=project

    respond_to do |format|
      format.js # new_popup.html.erb
    end
  end

  def new_assay
    topic=Topic.find(params[:topic_id])
    @assay=Assay.new
    @assay.topic=topic

    respond_to do |f|
      f.js
    end
  end

  def create
    @experiment = Experiment.new(params[:experiment])    
    
    respond_to do |format|
      if @experiment.save
        format.html { redirect_to(@experiment) }
        format.xml { render :xml => @experiment, :status => :created, :location => @experiment }
      else
        format.html {render :action=>"new"}
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end

  end

  def create_topic
    id=params[:id]
    title=params[:title]
    project_id=params[:project_id]
    project=Project.find(project_id)
    
    raise Exception.new("Person not a member of the project passed") if !current_user.person.projects.include?(project)
    topic=Topic.new(:title=>title,:project=>project)
    topic.save!
    respond_to do |format|
      format.json { render :json=>{:status=>200,:new_topic=>[topic.id,topic.title]} }
    end
  end



  def topic_selected_ajax    
    if params[:topic_id] && params[:topic_id]!="0"
      topic=Topic.find(params[:topic_id])
      render :partial=>"assay_list",:locals=>{:topic=>topic}
    else
      render :partial=>"assay_list",:locals=>{:topic=>nil}
    end
  end

  def project_selected_ajax
    
    if params[:project_id] && params[:project_id]!=0
      topics=Topic.find(:all,:conditions=>{:project_id=>params[:project_id]})      
    end
    
    topics||=[]

    render :update do |page|
      page.replace_html "topic_collection",:partial=>"topic_list",:locals=>{:topics=>topics,:project_id=>params[:project_id]}      
    end

  end
  
end
