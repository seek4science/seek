class ModelsController < ApplicationController    
  
  include WhiteListHelper
  include IndexPager
  include DotGenerator
  include Seek::AssetsCommon
  
  before_filter :login_required
  
  before_filter :pal_or_admin_required,:only=> [:create_model_metadata,:update_model_metadata,:delete_model_metadata ]
  
  before_filter :find_assets, :only => [ :index ]
  before_filter :find_model_auth, :except => [ :build,:index, :new, :create,:create_model_metadata,:update_model_metadata,:delete_model_metadata,:request_resource,:preview , :test_asset_url]
  before_filter :find_display_model, :only=>[:show,:download,:execute,:builder,:simulate,:submit_to_jws]
  
  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]
  
  @@model_builder = Seek::JWSModelBuilder.new
  
  # GET /models
  # GET /models.xml
  
  def new_version
    if (handle_data nil)
      
      comments = params[:revision_comment]
      @model.content_blob = ContentBlob.new(:data => @data, :url=>@data_url)
      @model.content_type = params[:model][:content_type]
      @model.original_filename = params[:model][:original_filename]
      
      respond_to do |format|
        create_new_version comments
        format.html {redirect_to @model }
      end
    else
      flash[:error]=flash.now[:error]
      redirect_to @model
    end
  end    
  
  def delete_model_metadata
    attribute=params[:attribute]
    if attribute=="model_type"
      delete_model_type params
    elsif attribute=="model_format"
      delete_model_format params
    end
  end
  
  def builder
    saved_file=params[:saved_file]
    error=nil
    begin
      if saved_file
        supported=true
        @data_script_hash,@saved_file,@objects_hash,@error_keys = @@model_builder.saved_file_builder_content saved_file
      else
        supported = @@model_builder.is_supported?(@display_model)
        @data_script_hash,@saved_file,@objects_hash,@error_keys = @@model_builder.builder_content @display_model if supported  
      end
    rescue Exception=>e
      error=e
    end
    
    respond_to do |format|
      if error
        flash[:error]="JWS Online encountered a problem processing this model."
        format.html { redirect_to(@model,:version=>@display_model.version)}                      
      elsif !supported
        flash[:error]="This model is of neither SBML or JWS Online (Dat) format so cannot be used with JWS Online"
        format.html { redirect_to(@model,:version=>@display_model.version)}        
      else
        format.html
      end
    end
  end    
  
  def submit_to_jws
    following_action=params.delete("following_action")    
    
    @data_script_hash,@saved_file,@objects_hash,@error_keys = @@model_builder.construct @display_model,params
    if (@error_keys.empty?)
      if following_action == "simulate"
        @applet=@@model_builder.simulate @saved_file
      elsif following_action == "save_new_version"
        model_format=params.delete("saved_model_format") #only used for saving as a new version
        new_version_filename=params.delete("new_version_filename")
        new_version_comments=params.delete("new_version_comments")
        if model_format == "dat"
          url=@@model_builder.saved_dat_download_url @saved_file                    
        elsif model_format == "sbml"
          url=@@model_builder.sbml_download_url @saved_file          
        end
        if url
          downloader=Jerm::HttpDownloader.new
          data_hash = downloader.get_remote_data url
          @model.content_blob=ContentBlob.new(:data=>data_hash[:data])
          @model.content_type=data_hash[:content_type] 
          @model.original_filename=new_version_filename
        end
      end
    end
    respond_to do |format|      
      if @error_keys.empty? && following_action == "simulate"        
        format.html {render :action=>"simulate",:layout=>"no_sidebar"}
      elsif @error_keys.empty? && following_action == "save_new_version"
        create_new_version new_version_comments
        format.html {redirect_to @model }
      else
        format.html { render :action=>"builder" }
      end      
    end
  end
  
  def simulate
    error=nil
    begin
      supported = @@model_builder.is_supported?(@display_model)
      if supported
        @data_script_hash,saved_file,@objects_hash = @@model_builder.builder_content @display_model    
        @applet=@@model_builder.simulate saved_file
      end
    rescue Exception=>e
      error=e
    end
    
    respond_to do |format|
      if error
        flash[:error]="JWS Online encountered a problem processing this model."
        format.html { redirect_to(@model,:version=>@display_model.version)}                      
      elsif !supported
        flash[:error]="This model is of neither SBML or JWS Online (Dat) format so cannot be used with JWS Online"
        format.html { redirect_to(@model,:version=>@display_model.version)}        
      else
        format.html {render :layout=>"no_sidebar"}
      end
    end
    
  end
  
  def update_model_metadata
    attribute=params[:attribute]
    if attribute=="model_type"
      update_model_type params
    elsif attribute=="model_format"
      update_model_format params
    end
  end
  
  def delete_model_type params
    id=params[:selected_model_type_id]
    model_type=ModelType.find(id)
    success=false
    if (model_type.models.empty?)
      if model_type.delete
        msg="OK. #{model_type.title} was successfully removed."
        success=true
      else
        msg="ERROR. There was a problem removing #{model_type.title}"
      end
    else
      msg="ERROR - Cannot delete #{model_type.title} because it is in use."
    end
    
    render :update do |page|
      page.replace_html "model_type_selection",collection_select(:model, :model_type_id, ModelType.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_type_selection_changed();" })
      page.replace_html "model_type_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_type_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_type_info"
    end
    
  end
  
  def delete_model_format params
    id=params[:selected_model_format_id]
    model_format=ModelFormat.find(id)
    success=false
    if (model_format.models.empty?)
      if model_format.delete
        msg="OK. #{model_format.title} was successfully removed."
        success=true
      else
        msg="ERROR. There was a problem removing #{model_format.title}"
      end
    else
      msg="ERROR - Cannot delete #{model_format.title} because it is in use."
    end
    
    render :update do |page|
      page.replace_html "model_format_selection",collection_select(:model, :model_format_id, ModelFormat.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_format_selection_changed();" })
      page.replace_html "model_format_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_format_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_format_info"      
    end    
  end
  
  def create_model_metadata
    attribute=params[:attribute]
    if attribute=="model_type"
      create_model_type params
    elsif attribute=="model_format"
      create_model_format params
    end
  end
  
  def update_model_type params
    title=white_list(params[:updated_model_type])
    id=params[:updated_model_type_id]
    success=false
    model_type_with_matching_title=ModelType.find(:first,:conditions=>{:title=>title})
    if model_type_with_matching_title.nil? || model_type_with_matching_title.id.to_s==id
      m=ModelType.find(id)
      m.title=title
      if m.save
        msg="OK. Model type changed to #{title}."
        success=true
      else
        msg="ERROR - There was a problem changing to #{title}"
      end
    else
      msg="ERROR - Another model type with #{title} already exists"
    end
    
    render :update do |page|
      page.replace_html "model_type_selection",collection_select(:model, :model_type_id, ModelType.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_type_selection_changed();" })
      page.replace_html "model_type_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_type_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_type_info"
    end
    
  end
  
  
  def create_model_type params
    title=white_list(params[:model_type])
    success=false
    if ModelType.find(:first,:conditions=>{:title=>title}).nil?
      new_model_type=ModelType.new(:title=>title)
      if new_model_type.save
        msg="OK. Model type #{title} added."
        success=true
      else
        msg="ERROR - There was a problem adding #{title}"
      end
    else
      msg="ERROR - Model type #{title} already exists"
    end
    
    
    render :update do |page|
      page.replace_html "model_type_selection",collection_select(:model, :model_type_id, ModelType.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_type_selection_changed();" })
      page.replace_html "model_type_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_type_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_type_info"
      page << "model_types_for_deletion.push(#{new_model_type.id});" if success
      
    end
  end
  
  def create_model_format params
    title=white_list(params[:model_format])
    success=false
    if ModelFormat.find(:first,:conditions=>{:title=>title}).nil?
      new_model_format=ModelFormat.new(:title=>title)
      if new_model_format.save
        msg="OK. Model format #{title} added."
        success=true
      else
        msg="ERROR - There was a problem adding #{title}"
      end
    else
      msg="ERROR - Another model format #{title} already exists"
    end
    
    
    render :update do |page|
      page.replace_html "model_format_selection",collection_select(:model, :model_format_id, ModelFormat.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_format_selection_changed();" })
      page.replace_html "model_format_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_format_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_format_info"
      page << "model_formats_for_deletion.push(#{new_model_format.id});" if success
      
    end
  end
  
  def update_model_format params
    title=white_list(params[:updated_model_format])
    id=params[:updated_model_format_id]
    success=false    
    model_format_with_matching_title=ModelFormat.find(:first,:conditions=>{:title=>title})
    if model_format_with_matching_title.nil? || model_format_with_matching_title.id.to_s==id
      m=ModelFormat.find(id)
      m.title=title
      if m.save
        msg="OK. Model format changed to #{title}."
        success=true
      else
        msg="ERROR - There was a problem changing to #{title}"
      end
    else
      msg="ERROR - Another model format with #{title} already exists"
    end
    
    render :update do |page|
      page.replace_html "model_format_selection",collection_select(:model, :model_format_id, ModelFormat.find(:all), :id, :title, {:include_blank=>"Not specified"},{:onchange=>"model_format_selection_changed();" })
      page.replace_html "model_format_info","#{msg}<br/>"
      info_colour= success ? "green" : "red"
      page << "$('model_format_info').style.color='#{info_colour}';"
      page.visual_effect :appear, "model_format_info"
    end
    
  end
  
  
  # GET /models/1
  # GET /models/1.xml
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @model.last_used_at
    
    # update timestamp in the current Model record
    # (this will also trigger timestamp update in the corresponding Asset)
    @model.last_used_at = Time.now
    @model.save_without_timestamping
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml
      format.svg { render :text=>to_svg(@model,params[:deep]=='true',@model)}
      format.dot { render :text=>to_dot(@model,params[:deep]=='true',@model)}
      format.png { render :text=>to_png(@model,params[:deep]=='true',@model)}
    end
  end
  
  # GET /models/new
  # GET /models/new.xml
  def new    
    respond_to do |format|
      if Authorization.is_member?(current_user.person_id, nil, nil)
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new Models. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to models_path }
      end
    end
  end
  
  # GET /models/1/edit
  def edit
    
  end
  
  # POST /models
  # POST /models.xml
  def create    
    if handle_data
      @model = Model.new(params[:model])
      @model.contributor = current_user
      @model.content_blob = ContentBlob.new(:data => @data,:url=>@data_url)
      
      respond_to do |format|
        if @model.save
          # the Model was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@model, current_user, params)
          
          # update attributions
          Relationship.create_or_update_attributions(@model, params[:attributions])
          
          # update related publications
          Relationship.create_or_update_attributions(@model, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}.to_json, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?
          
          #Add creators
          AssetsCreator.add_or_update_creator_list(@model, params[:creators])
          
          if policy_err_msg.blank?
            flash[:notice] = 'Model was successfully uploaded and saved.'
            format.html { redirect_to model_path(@model) }
          else
            flash[:notice] = "Model was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'models', :id => @model, :action => "edit" }
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
  
  # GET /models/1/download
  def download
    # update timestamp in the current Model record
    # (this will also trigger timestamp update in the corresponding Asset)
    @model.last_used_at = Time.now
    @model.save_without_timestamping    
    
    handle_download @display_model
  end
  
  # PUT /models/1
  # PUT /models/1.xml
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:model]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:model].delete(column_name)
      end
      
      # update 'last_used_at' timestamp on the Model
      params[:model][:last_used_at] = Time.now
    end
    
    respond_to do |format|
      if @model.update_attributes(params[:model])
        # the Model was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@model, current_user, params)
        
        # update attributions
        Relationship.create_or_update_attributions(@model, params[:attributions])
        
        # update related publications
        Relationship.create_or_update_attributions(@model, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}.to_json, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?
        
        #update creators
        AssetsCreator.add_or_update_creator_list(@model, params[:creators])
        
        if policy_err_msg.blank?
          flash[:notice] = 'Model metadata was successfully updated.'
          format.html { redirect_to model_path(@model) }
        else
          flash[:notice] = "Model metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'models', :id => @model, :action => "edit" }
        end
      else
        format.html {
          set_parameters_for_sharing_form()
          render :action => "edit"
        }
      end
    end
  end
  
  # DELETE /models/1
  # DELETE /models/1.xml
  def destroy
    @model = Model.find(params[:id])
    @model.destroy
    
    respond_to do |format|
      format.html { redirect_to(models_url) }
      format.xml  { head :ok }
    end
  end
  
  def preview
    
    element = params[:element]
    model = Model.find_by_id(params[:id])
    
    render :update do |page|
      if model && Authorization.is_authorized?("show", nil, model, current_user)
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>model}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end
  
  def request_resource
    resource = Model.find(params[:id])
    details = params[:details]
    
    Mailer.deliver_request_resource(current_user,resource,details,base_host)
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end  
  
  protected
  
  def create_new_version comments
    if @model.save_as_new_version(comments)
      flash[:notice]="New version uploaded - now on version #{@model.version}"
    else
      flash[:error]="Unable to save new version"          
    end    
  end
  
  def default_items_per_page
    return 2
  end
  
  def find_display_model
    if @model
      @display_model = params[:version] ? @model.find_version(params[:version]) : @model.latest_version
    end
  end
  
  def find_model_auth
    begin
      action=action_name
      action="download" if action=="execute"
      
      model = Model.find(params[:id])
      
      if Authorization.is_authorized?(action, nil, model, current_user)
        @model = model
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to models_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Model or you are not authorized to view it"
        format.html { redirect_to models_path }
      end
      return false
    end
  end
  
  
  def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""
    
    # obtain a policy to use
    if @model
      if (policy = @model.policy)
        # Model exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @model.project && (policy = @model.project.default_policy)
        # Model exists, but policy not attached - try to use project default policy, if exists
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
    @resource_type = "Model"
    @favourite_groups = current_user.favourite_groups
    @resource=@model
    
    @all_people_as_json = Person.get_all_as_json
    
    @enable_black_white_listing = @resource.nil? || !@resource.contributor.nil?
    
  end
  
end
