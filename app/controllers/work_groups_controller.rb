class WorkGroupsController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  
  
  # GET /groups
  # GET /groups.xml
  def index
    @groups = WorkGroup.all
    options = {:is_collection=>true}
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
      format.json {render json: JSONAPI::Serializer.serialize(@groups,options)}

    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    options = {:is_collection=>false}
    @group = WorkGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
      format.json {render json: JSONAPI::Serializer.serialize(@group,options)}

    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = WorkGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = WorkGroup.find(params[:id])
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = WorkGroup.new(params[:group])

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = WorkGroup.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = WorkGroup.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end
  

end
