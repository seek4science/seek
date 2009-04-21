class DataFilesController < ApplicationController

  before_filter :login_required

  before_filter :find_data_files, :only => [ :index ]
  before_filter :find_data_file_auth, :except => [ :index, :new, :create ]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]


  def new
    respond_to do |format|
      if Authorization.is_member?(current_user.person_id, nil, nil)
        format.html # new.html.erb
      else
        flash[:error] = "You are not authorized to upload new Data files. Only members of known projects, institutions or work groups are allowed to create new content."
        format.html { redirect_to data_files_path }
      end
    end
  end

  def create
    if (params[:data_file][:data]).blank?
      respond_to do |format|
        flash.now[:error] = "Please select a file to upload."
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    elsif (params[:data_file][:data]).size == 0
      respond_to do |format|
        flash.now[:error] = "The file that you have selected is empty. Please check your selection and try again!"
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    else
      # create new Data file and content blob - non-empty file was selected

      # prepare some extra metadata to store in Data files instance
      params[:data_file][:contributor_type] = "User"
      params[:data_file][:contributor_id] = current_user.id

      # store properties and contents of the file temporarily and remove the latter from params[],
      # so that when saving main object params[] wouldn't contain the binary data anymore
      params[:data_file][:content_type] = (params[:data_file][:data]).content_type
      params[:data_file][:original_filename] = (params[:data_file][:data]).original_filename
      data = params[:data_file][:data].read
      params[:data_file].delete('data')

      # store source and quality of the new Data file (this will be kept in the corresponding asset object eventually)
      # TODO set these values to something more meaningful, if required for Data files
      params[:data_file][:source_type] = "upload"
      params[:data_file][:source_id] = nil
      params[:data_file][:quality] = nil


      @data_file = DataFile.new(params[:data_file])
      @data_file.content_blob = ContentBlob.new(:data => data)

      respond_to do |format|
        if @data_file.save
          # the Data file was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@data_file, current_user, params)

          # update attributions
          Relationship.create_or_update_attributions(@data_file, params[:attributions])

          if policy_err_msg.blank?
            flash[:notice] = 'Data file was successfully uploaded and saved.'
            format.html { redirect_to data_file_path(@data_file) }
          else
            flash[:notice] = "Data file was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'data_files', :id => @data_file, :action => "edit" }
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

  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @data_file.last_used_at

    # update timestamp in the current Model record
    # (this will also trigger timestamp update in the corresponding Asset)
    @data_file.last_used_at = Time.now
    @data_file.save_without_timestamping

    respond_to do |format|
      format.html # show.html.erb
    end
  end


  protected
  
  def find_data_files
    found = DataFile.find(:all,
                     :order => "title")

    # this is only to make sure that actual binary data isn't sent if download is not
    # allowed - this is to increase security & speed of page rendering;
    # further authorization will be done for each item when collection is rendered
    found.each do |data_file|
      data_file.content_blob.data = nil unless Authorization.is_authorized?("download", nil, data_file, current_user)
    end

    @data_files = found
  end


  def find_data_file_auth
    begin
      action=action_name      

      data_file = DataFile.find(params[:id])

      if Authorization.is_authorized?(action_name, nil, data_file, current_user)
        @data_file = data_file
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to data_files_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Data file or you are not authorized to view it"
        format.html { redirect_to data_files_path }
      end
      return false
    end
  end


  def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if defined?(@data_file) && @data_file.asset
      if (policy = @data_file.asset.policy)
        # Datafile exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @data_file.asset.project && (policy = @data_file.asset.project.default_policy)
        # Datafile exists, but policy not attached - try to use project default policy, if exists
        policy_type = "project"
      end
    end

    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Datafile exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Datafile exists, but policy wasn't attached to it;
      #    (also, Datafile wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Datafile) OR system default
      projects = current_user.person.projects
      if projects.length == 1 && (proj_default = projects[0].default_policy)
        policy = proj_default
        policy_type = "project"
      else
        policy = Policy.default(current_user)
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
    @resource_type = "DataFile"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json


  end

end
