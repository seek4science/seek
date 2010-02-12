require 'model_execution'

class ModelsController < ApplicationController
  #FIXME: re-add REST for each of the core methods

  include ModelExecution
  include WhiteListHelper

  before_filter :login_required

  before_filter :pal_or_admin_required,:only=> [:create_model_metadata,:update_model_metadata,:delete_model_metadata ]

  before_filter :find_models, :only => [ :index ]
  before_filter :find_model_auth, :except => [ :index, :new, :create,:create_model_metadata,:update_model_metadata,:delete_model_metadata ]
  before_filter :find_display_model, :only=>[:show,:download]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  # GET /models
  # GET /models.xml
  def index
    @models=Authorization.authorize_collection("show",@models,current_user)
    @models=Model.paginate_after_fetch(@models, :page=>params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@models}
    end
  end

  def new_version
    data = params[:data].read
    comments = params[:revision_comment]
    @model.content_blob = ContentBlob.new(:data => data)
    @model.content_type = params[:data].content_type
    @model.original_filename = params[:data].original_filename
    respond_to do |format|
      if @model.save_as_new_version(comments)
        flash[:notice]="New version uploaded - now on version #{@model.version}"
      else
        flash[:error]="Unable to save new version"          
      end
      format.html {redirect_to @model }
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

  def execute
    version=params[:version]
    @applet= jws_execution_applet @model.find_version(version)
    
    if @applet.instance_of?(Net::HTTPInternalServerError)      
      @error_details=@applet.body.gsub(/<head\>.*<\/head>/,"")
    end

    render :update do |page|
      page.replace_html "execute_model",:partial=>"execute_applet"
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
    if (params[:model][:data]).blank?
      respond_to do |format|
        flash.now[:error] = "Please select a file to upload."
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    elsif (params[:model][:data]).size == 0
      respond_to do |format|
        flash.now[:error] = "The file that you have selected is empty. Please check your selection and try again!"
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    else
      # create new Model and content blob - non-empty file was selected

      # prepare some extra metadata to store in Model instance
      params[:model][:contributor_type] = "User"
      params[:model][:contributor_id] = current_user.id

      # store properties and contents of the file temporarily and remove the latter from params[],
      # so that when saving main object params[] wouldn't contain the binary data anymore
      params[:model][:content_type] = (params[:model][:data]).content_type
      params[:model][:original_filename] = (params[:model][:data]).original_filename
      data = params[:model][:data].read
      params[:model].delete('data')

      # store source and quality of the new Model (this will be kept in the corresponding asset object eventually)
      # TODO set these values to something more meaningful, if required for Models
      params[:model][:source_type] = "upload"
      params[:model][:source_id] = nil
      params[:model][:quality] = nil


      @model = Model.new(params[:model])
      @model.content_blob = ContentBlob.new(:data => data)

      respond_to do |format|
        if @model.save
          # the Model was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@model, current_user, params)

          # update attributions
          Relationship.create_or_update_attributions(@model, params[:attributions])
          
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

  # GET /models/1;download
  def download
    # update timestamp in the current Model record
    # (this will also trigger timestamp update in the corresponding Asset)
    @model.last_used_at = Time.now
    @model.save_without_timestamping

    #This should be fixed to work in the future, as the downloaded version doesnt get its last_used_at updated
    #@display_model.last_used_at = Time.now
    #@display_model.save_without_timestamping

    if @display_model.content_blob.url.blank?
      send_data @display_model.content_blob.data, :filename => @display_model.original_filename, :content_type => @display_model.content_type, :disposition => 'attachment'
    else
      download_jerm_resource @display_model
    end
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

      # update 'contributor' of the Model to current user (this under no circumstances should update
      # 'contributor' of the corresponding Asset: 'contributor' of the Asset is the "owner" of this
      # Model, e.g. the original uploader who has unique rights to manage this Model; 'contributor' of the
      # MOdel on the other hand is merely the last user to edit it)
      params[:model][:contributor_type] = current_user.class.name
      params[:model][:contributor_id] = current_user.id
    end

    respond_to do |format|
      if @model.update_attributes(params[:model])
        # the Model was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@model, current_user, params)

        # update attributions
        Relationship.create_or_update_attributions(@model, params[:attributions])
        
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

  protected

  def default_items_per_page
    return 2
  end

  def find_models
    found = Model.find(:all,
                     :order => "title")

    # this is only to make sure that actual binary data isn't sent if download is not
    # allowed - this is to increase security & speed of page rendering;
    # further authorization will be done for each item when collection is rendered
    found.each do |model|
      model.content_blob.data = nil unless Authorization.is_authorized?("download", nil, model, current_user)
    end

    @models = found    
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
    if defined?(@model) && @model.asset
      if (policy = @model.asset.policy)
        # Model exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @model.project && (policy = @model.project.default_policy)
        # Model exists, but policy not attached - try to use project default policy, if exists
        policy_type = "project"
      end
    end

    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Model exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Model exists, but policy wasn't attached to it;
      #    (also, Model wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Model) OR system default
      projects = current_user.person.projects
      if projects.length == 1 && (proj_default = projects[0].default_policy)
        policy = proj_default
        policy_type = "project"
      else
        policy = Policy.default()
        policy_type = "system"
      end
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

    @all_people_as_json = Person.get_all_as_json
    

  end

end
