class SopsController < ApplicationController  
  
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon
  
  before_filter :login_required
  before_filter :find_assets, :only => [ :index ]  
  before_filter :find_sop_auth, :except => [ :index, :new, :create, :request_resource,:preview , :test_asset_url]
  before_filter :find_display_sop, :only=>[:show,:download]
  
  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]
  
  def new_version
    if (handle_data nil)      
      comments=params[:revision_comment]
      
      @sop.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object, :url=>@data_url)
      @sop.content_type = params[:sop][:content_type]
      @sop.original_filename = params[:sop][:original_filename]
      
      conditions = @sop.experimental_conditions
      respond_to do |format|
        if @sop.save_as_new_version(comments)
          #Duplicate experimental conditions
          conditions.each do |con|
            new_con = con.clone
            new_con.sop_version = @sop.version
            new_con.save
          end
          flash[:notice]="New version uploaded - now on version #{@sop.version}"
        else
          flash[:error]="Unable to save new version"          
        end
        format.html {redirect_to @sop }
      end
    else
      flash[:error]=flash.now[:error] 
      redirect_to @sop
    end
    
  end
  
  # GET /sops/1
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @sop.last_used_at
    
    # update timestamp in the current SOP record 
    # (this will also trigger timestamp update in the corresponding Asset)
    if @sop.instance_of?(Sop)
      @sop.last_used_at = Time.now
      @sop.save_without_timestamping
    end  
    
    respond_to do |format|
      format.html
      format.xml
      format.svg { render :text=>to_svg(@sop,params[:deep]=='true',@sop)}
      format.dot { render :text=>to_dot(@sop,params[:deep]=='true',@sop)}
      format.png { render :text=>to_png(@sop,params[:deep]=='true',@sop)}
    end
  end
  
  # GET /sops/1/download
  def download
    # update timestamp in the current SOP record 
    # (this will also trigger timestamp update in the corresponding Asset)
    @sop.last_used_at = Time.now
    @sop.save_without_timestamping
    
    handle_download @display_sop
  end
  
  # GET /sops/new
  def new
    @sop=Sop.new
    respond_to do |format|
      if Authorization.is_member?(current_user.person_id, nil, nil)
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new SOPs. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to sops_path }
      end
    end
  end
  
  # GET /sops/1/edit
  def edit
    
  end
  
  # POST /sops
  def create
    if handle_data            
      
      @sop = Sop.new(params[:sop])
      @sop.contributor=current_user
      @sop.content_blob = ContentBlob.new(:tmp_io_object => @tmp_io_object,:url=>@data_url)
      
      respond_to do |format|
        if @sop.save
          # the SOP was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@sop, current_user, params)
          
          # update attributions
          Relationship.create_or_update_attributions(@sop, params[:attributions])
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
          
          if policy_err_msg.blank?
            flash[:notice] = 'SOP was successfully uploaded and saved.'
            format.html { redirect_to sop_path(@sop) }
          else
            flash[:notice] = "SOP was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'sops', :id => @sop, :action => "edit" }
          end
        else
          format.html { 
            set_parameters_for_sharing_form()
            render :action => "new" 
          }
        end
      end
    end
  end
  
  
  # PUT /sops/1
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:sop]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:sop].delete(column_name)
      end
      
      # update 'last_used_at' timestamp on the SOP
      params[:sop][:last_used_at] = Time.now
    end
    
    respond_to do |format|
      if @sop.update_attributes(params[:sop])
        # the SOP was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@sop, current_user, params)
        
        # update attributions
        Relationship.create_or_update_attributions(@sop, params[:attributions])
        
        #update authors
        AssetsCreator.add_or_update_creator_list(@sop, params[:creators])
        
        if policy_err_msg.blank?
          flash[:notice] = 'SOP metadata was successfully updated.'
          format.html { redirect_to sop_path(@sop) }
        else
          flash[:notice] = "SOP metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'sops', :id => @sop, :action => "edit" }
        end
      else
        format.html { 
          set_parameters_for_sharing_form()
          render :action => "edit" 
        }
      end
    end
  end
  
  # DELETE /sops/1
  def destroy
    @sop.destroy
    
    respond_to do |format|
      format.html { redirect_to(sops_url) }
    end
  end
  
  
  def preview
    
    element=params[:element]
    sop=Sop.find_by_id(params[:id])
    
    render :update do |page|
      if sop && Authorization.is_authorized?("show", nil, sop, current_user)
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>sop}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end
  
  def request_resource
    resource = Sop.find(params[:id])
    details = params[:details]
    
    Mailer.deliver_request_resource(current_user,resource,details,base_host)
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end
  
  protected
  
  
  
  def find_display_sop
    if @sop
      @display_sop = params[:version] ? @sop.find_version(params[:version]) : @sop.latest_version
    end
  end
  
  def find_sop_auth
    begin
      sop = Sop.find(params[:id])             
      
      if Authorization.is_authorized?(action_name, nil, sop, current_user)
        @sop = sop
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to sops_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the SOP or you are not authorized to view it"
        format.html { redirect_to sops_path }
      end
      return false
    end
  end
  
  
  def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""
    
    # obtain a policy to use
    if @sop
      if (policy = @sop.policy)
        # SOP exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @sop.project && (policy = @sop.project.default_policy)
        # SOP exists, but policy not attached - try to use project default policy, if exists
        policy_type = "project"
      end
    end
    
    unless policy
      policy = Policy.default()
      policy_type = "system"
    end
    
    # set the parameters
    # ..from policy
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    @access_mode = policy.access_type
    @use_custom_sharing = (policy.use_custom_sharing == true || policy.use_custom_sharing == 1)
    @use_whitelist = (policy.use_whitelist == true || policy.use_whitelist == 1)
    @use_blacklist = (policy.use_blacklist == true || policy.use_blacklist == 1)
    
    # ..other
    @resource_type = "SOP"
    @favourite_groups = current_user.favourite_groups
    @resource = @sop
    
    @all_people_as_json = Person.get_all_as_json
    
    @enable_black_white_listing = @resource.nil? || !@resource.contributor.nil?
    
  end
  
end
