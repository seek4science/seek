
require 'simple-spreadsheet-extractor'

class DataFilesController < ApplicationController

  include IndexPager
  include SysMODB::SpreadsheetExtractor
  include MimeTypesHelper  

  before_filter :login_required

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_data_file_auth, :except => [ :index, :new, :create, :request_resource]
  before_filter :find_display_data_file, :only=>[:show,:download]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]  
  
  def new_version
    data = params[:data].read
    comments=params[:revision_comment]
    @data_file.content_blob = ContentBlob.new(:data => data)
    @data_file.content_type = params[:data].content_type
    @data_file.original_filename=params[:data].original_filename
    factors = @data_file.studied_factors
    respond_to do |format|
      if @data_file.save_as_new_version(comments)
        #Duplicate studied factors
        factors.each do |f|
          new_f = f.clone
          new_f.data_file_version = @data_file.version
          new_f.save
        end
        flash[:notice]="New version uploaded - now on version #{@data_file.version}"
      else
        flash[:error]="Unable to save new version"          
      end
      format.html {redirect_to @data_file }
    end
  end

  # DELETE /models/1
  # DELETE /models/1.xml
  def destroy
    #FIXME: Double check auth is working for deletion. Also, maybe should only delete if not associated with any assays.
    @data_file.destroy
    
    respond_to do |format|
      format.html { redirect_to(data_files_url) }
      format.xml  { head :ok }
    end
  end


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
      
      @data_file = DataFile.new(params[:data_file])
      @data_file.content_blob = ContentBlob.new(:data => data)

      respond_to do |format|
        if @data_file.save
          # the Data file was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@data_file, current_user, params)

          # update attributions
          Relationship.create_or_update_attributions(@data_file, params[:attributions])
          
          # update related publications
          Relationship.create_or_update_attributions(@data_file, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}, Relationship::RELATED_TO_PUBLICATION)

          #Add creators
          AssetsCreator.add_or_update_creator_list(@data_file, params[:creators])

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

    # update timestamp in the current Data file record
    # (this will also trigger timestamp update in the corresponding Asset)
    @data_file.last_used_at = Time.now
    @data_file.save_without_timestamping

    respond_to do |format|
      format.html # show.html.erb
      format.xml
    end
  end

  def edit

  end

  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:data_file]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:data_file].delete(column_name)
      end

      # update 'last_used_at' timestamp on the DataFile
      params[:data_file][:last_used_at] = Time.now
    end

    respond_to do |format|
      if @data_file.update_attributes(params[:data_file])
        # the Data file was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@data_file, current_user, params)

        # update attributions
        Relationship.create_or_update_attributions(@data_file, params[:attributions])
        
        # update related publications
        Relationship.create_or_update_attributions(@data_file, params[:related_publication_ids].collect {|i| ["Publication", i.split(",").first]}.to_json, Relationship::RELATED_TO_PUBLICATION)

        
        #update creators
        AssetsCreator.add_or_update_creator_list(@data_file, params[:creators])

        if policy_err_msg.blank?
            flash[:notice] = 'Data file metadata was successfully updated.'
            format.html { redirect_to data_file_path(@data_file) }
          else
            flash[:notice] = "Data file metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'data_files', :id => @data_file, :action => "edit" }
          end
      else
        format.html {
          set_parameters_for_sharing_form()
          render :action => "edit"
        }
      end
    end
  end

  # GET /data_files/1;download
  def download
    # update timestamp in the current data file record
    # (this will also trigger timestamp update in the corresponding Asset)
    @data_file.last_used_at = Time.now
    @data_file.save_without_timestamping

    #This should be fixed to work in the future, as the downloaded version doesnt get its last_used_at updated
    #@display_data_file.last_used_at = Time.now
    #@display_data_file.save_without_timestamping

    #Send data stored in database if no url specified
    if @display_data_file.content_blob.url.blank?
      if @display_data_file.content_blob.file_exists?
        send_file @display_data_file.content_blob.filepath, :filename => @display_data_file.original_filename, :content_type => @display_data_file.content_type, :disposition => 'attachment'
      else
        send_data @display_data_file.content_blob.data, :filename => @display_data_file.original_filename, :content_type => @display_data_file.content_type, :disposition => 'attachment'  
      end
      
    else #otherwise redirect to the provided download url. this will need to be changed to support authorization
      download_jerm_resource @display_data_file
    end
  end 

  def data
    @data_file =  DataFile.find(params[:id])
    if ["xls","xlsx"].include?(mime_extension(@data_file.content_type))
      xml = spreadsheet_to_xml(open(@data_file.content_blob.filepath))
      respond_to do |format|
        format.html #currently complains about a missing template, but we don't want people using this for now - its purely XML
        format.xml {render :xml=>xml }
      end
    else
     respond_to do |format|
        flash[:error] = "Unable to view contents of this data file"
        format.html { redirect_to @data_file,:format=>"html" }
      end
    end
  end
  
  def preview
    element=params[:element]
    data_file=@data_file
    
    render :update do |page|
      if data_file && Authorization.is_authorized?("show", nil, data_file, current_user)
        page.replace_html element,:partial=>"assets/resource_preview",:locals=>{:resource=>data_file}
      else
        page.replace_html element,:text=>"Nothing is selected to preview."
      end
    end
  end  
  
  def request_resource
    resource = DataFile.find(params[:id])
    details = params[:details]
    
    Mailer.deliver_request_resource(current_user,resource,details,base_host)
    
    render :update do |page|
      page[:requesting_resource_status].replace_html "An email has been sent on your behalf to <b>#{resource.managers.collect{|m| m.name}.join(", ")}</b> requesting the file <b>#{h(resource.title)}</b>."
    end
  end  
  
  protected    

  def find_display_data_file
    if @data_file
      @display_data_file = params[:version] ? @data_file.find_version(params[:version]) : @data_file.latest_version
    end
  end

  def find_data_file_auth
    begin      
      
      action=action_name
      action="download" if action=="data"
      data_file = DataFile.find(params[:id])

      if Authorization.is_authorized?(action, nil, data_file, current_user)
        @data_file = data_file
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to data_files_path }
          #FIXME: this isn't the right response - should return with an unauthorized status code
          format.xml { redirect_to data_files_path(:format=>"xml") }
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
    if @data_file
      if (policy = @data_file.policy)
        # Datafile exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @data_file.project && (policy = @data_file.project.default_policy)
        # Datafile exists, but policy not attached - try to use project default policy, if exists
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
    @resource_type = "DataFile"
    @favourite_groups = current_user.favourite_groups
    @resource = @data_file

    @all_people_as_json = Person.get_all_as_json
    
    @enable_black_white_listing = @resource.nil? || !@resource.contributor.nil?

  end

end
