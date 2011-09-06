require 'white_list_helper'

class WorkGroupsController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  before_filter :set_no_layout, :only => [ :review_popup ]
  before_filter :find_work_group, :only => [ :review_popup ]
  
  protect_from_forgery :except => [ :review_popup ]
  
  
  # GET /groups
  # GET /groups.xml
  def index
    @groups = WorkGroup.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = WorkGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
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
  
  
  # POST /work_groups/review
  # will be called to display the RedBox popup for reviewing member permissions of workgroup
  # (or project / institutions - as these are, essentially, work groups, too)
  def review_popup
    respond_to do |format|
      format.js # review_popup.html.erb
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
  

  private
  
  def find_work_group
    # work group members list is public - no need for any security checks
    group_type = white_list(params[:type])
    group_id = white_list(params[:id])
    access_type = white_list(params[:access_type]).to_i
    
    begin
      group_instance = group_type.constantize.find group_id
      @error_text = nil
      @group_instance = group_instance
      case @group_instance.class.name
        when "WorkGroup"
          @group_name = @group_instance.project.name + " @ " + @group_instance.institution.name
        when "Project", "Institution"
          @group_name = @group_instance.name
        else
          @group_name = "unknown"
      end
      @access_type = access_type
      
    rescue ActiveRecord::RecordNotFound
      @error_text = "#{group_type} with ID = #{group_id} wasn't found."
    rescue NameError
      @error_text = "Unknown work group type: #{group_type}"
    end
    
    respond_to do |format|
      format.js # review_popup.html.erb
    end
  end
end
