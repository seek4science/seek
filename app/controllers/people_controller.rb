class PeopleController < ApplicationController
  
  before_filter :login_required,:except=>[:select,:userless_project_selected_ajax,:create,:new]
  before_filter :current_user_exists,:only=>[:select,:userless_project_selected_ajax,:create,:new]
  before_filter :profile_belongs_to_current_or_is_admin, :only=>[:edit, :update]
  before_filter :profile_is_not_another_admin_except_me, :only=>[:edit,:update]
  before_filter :is_user_admin_auth, :only=>[:destroy]
  before_filter :is_user_admin_or_personless, :only=>:new
  
  
  def auto_complete_for_tools_name
    render :json => Person.tool_counts.map(&:name).to_json
  end

  def auto_complete_for_expertise_name
    render :json => Person.expertise_counts.map(&:name).to_json
  end
  
  protect_from_forgery :only=>[]
  
  # GET /people
  # GET /people.xml
  def index
    if (!params[:expertise].nil?)
      @expertise_or_tools=params[:expertise]
      @people=Person.tagged_with(@expertise_or_tools, :on=>:expertise)
      @people=@people.select{|p| !p.is_dummy}
    elsif (!params[:tools].nil?)
      @expertise_or_tools=params[:tools]
      @people=Person.tagged_with(@expertise_or_tools, :on=>:tools)
      @people=@people.select{|p| !p.is_dummy}
    else
      @people = Person.find(:all, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>:last_name,:conditions=>{:is_dummy=>false})
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people.to_xml}
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @person.to_xml}
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @tags_tools = Person.tool_counts.sort{|a,b| a.name<=>b.name}
    @tags_expertise = Person.expertise_counts.sort{|a,b| a.name<=>b.name}

    @person = Person.new

    respond_to do |format|
      format.html { render :action=>"new",:layout=>"logged_out" }
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    @tags_tools = Person.tool_counts.sort{|a,b| a.name<=>b.name}
    @tags_expertise = Person.expertise_counts.sort{|a,b| a.name<=>b.name}

    @person = Person.find(params[:id])
  end

  #GET /people/select
  #
  #Page for after registration that allows you to select yourself from a list of
  #people yet to be assigned, or create a new one if you don't exist
  def select
    @userless_projects=Project.with_userless_people
    @userless_projects.sort!{|a,b|a.name<=>b.name}    
    @person = Person.new

    render :action=>"select",:layout=>"logged_out"
  end


  # POST /people
  # POST /people.xml
  def create
    @person = Person.new(params[:person])
    redirect_action="new"
    if !params[:tool].nil?
      tools_list = params[:tool][:list]
      @person.tool_list=tools_list
    end

    if !params[:expertise].nil?
      expertise_list = params[:expertise][:list]
      @person.expertise_list=expertise_list
    end
    
    if (current_user.person.nil?) #indicates a profile is being created during the registration process
      current_user.person=@person
      @userless_projects=Project.with_userless_people
      @userless_projects.sort!{|a,b|a.name<=>b.name}
      is_member=params[:sysmo_member]

      if (is_member)
        member_details=params[:sysmo_member_details]
        #FIXME: do something with the details if they have been indicated as being a sysmo member
      end

      redirect_action="select"
    end
    
    respond_to do |format|
      if @person.save && current_user.save
        flash[:notice] = 'Person was successfully created.'
        format.html { redirect_to(@person) }
        format.xml  { render :xml => @person, :status => :created, :location => @person }
      else        
        format.html { render :action => redirect_action,:layout=>"logged_out" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person = Person.find(params[:id])
    
    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    avatar_id = params[:person].delete(:avatar_id).to_i
    @person.avatar_id = ((avatar_id.kind_of?(Fixnum) && avatar_id > 0) ? avatar_id : nil)
    
    if !params[:tool].nil?
      tools_list = params[:tool][:list]
      @person.tool_list=tools_list
    end

    if !params[:expertise].nil?
      expertise_list = params[:expertise][:list]
      @person.expertise_list=expertise_list
    end
    
    # some "Person" instances might not have a "User" associated with them - because the user didn't register yet
    if current_user.is_admin?
      unless @person.user.nil?
        @person.user.can_edit_projects = (params[:can_edit_projects] ? true : false)
        @person.user.can_edit_institutions = (params[:can_edit_institutions] ? true : false)
        @person.user.save
      end
    end
    
    respond_to do |format|
      if @person.update_attributes(params[:person])
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @person = Person.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end
  
  def userless_project_selected_ajax
    project_id=params[:project_id]
    unless project_id=="0"
      proj=Project.find(project_id)
      @people=proj.userless_people
      @people.sort!{|a,b| a.last_name<=>b.last_name}
      render :partial=>"userless_people_list",:locals=>{:people=>@people}
    else
      render :text=>""
    end
    
  end

  private
  
  def profile_belongs_to_current_or_is_admin
    @person=Person.find(params[:id])
    unless @person == current_user.person || current_user.is_admin?
      error("Not the current person", "is invalid (not owner)")
      return false
    end
  end

  def profile_is_not_another_admin_except_me
    @person=Person.find(params[:id])
    if !@person.user.nil? && @person.user!=current_user && @person.user.is_admin?
      error("Cannot edit another Admins profile","is invalid(another admin)")
      return false
    end
  end

  def is_user_admin_or_personless
    unless current_user.is_admin? || current_user.person.nil?
      error("You do not have permission to create new people","Is invalid (not admin)")
      return false
    end
  end

  def current_user_exists
    if !current_user
      redirect_to("/")
    end
    !!current_user
  end
 
end
