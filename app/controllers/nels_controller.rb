class NelsController < ApplicationController
  before_action :nels_enabled?
  before_action :check_user_logged_in, only: :callback
  before_action :check_code_present, only: :callback
  before_action :project_membership_required, except: :callback
  before_action :authorize, except: :callback
  before_action :oauth_client
  before_action :nels_oauth_session, except: :callback
  before_action :rest_client, except: :callback

  rescue_from RestClient::Unauthorized, with: :unauthorized_response
  rescue_from RestClient::InternalServerError, with: :nels_error_response

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update(access_token: hash['access_token'], expires_in: 2.hours)
    if (match = params[:state].match(/assay_id:(\d+)/))
      params[:assay_id] = match[1].to_i
      redirect_to nels_path(assay_id: params[:assay_id])
    elsif (match = params[:state].match(/data_file_id:(\d+)/))
      redirect_to retrieve_nels_sample_metadata_data_file_path(match[1].to_i)
    else
      redirect_to nels_path
    end
  end

  def index
    @register_mode = params[:register_mode]
    respond_to do |format|
      format.html
    end
  end

  def new_dataset
    # Populate all the necessary information for the view
    @datasettypes = @rest_client.dataset_types

    @projects = []
    # If project information is already defined
    @projects = if params.has_key?(:project_id) && params.has_key?(:project_name)
                  [
                    {
                      'id' => params[:project_id],
                      'name' => params[:project_name]
                    }
                  ]
                else
                  @rest_client.projects
                end
    respond_to do |format|
      format.html
    end
  end

  def create_dataset
    begin
      @rest_client.create_dataset(params['project'], params['datasettype'], params['title'], params['description'])
    rescue RuntimeError => e
      flash[:error] = "Something went wrong interacting with NeLS, please try again later (#{e.class.name})"
    end
    render :index
  end

  def get_metadata
    begin
      file_name, file_path = @rest_client.get_metadata(params[:project_id].to_i, params[:dataset_id].to_i,
                                                       params[:subtype_name])
      send_file file_path, filename: file_name, disposition: 'attachment'
    rescue RuntimeError => e
      flash[:error] = "Something went wrong interacting with NeLS, please try again later (#{e.class.name})"
      redirect_to nels_path
    end
  end

  def add_metadata
    begin
      #raise 'add metadata currently broken'
      @rest_client.upload_metadata(params[:project_id].to_i, params[:dataset_id].to_i, params[:subtype_name],
                                   params['content_blobs'][0]['data'].path)
    rescue RuntimeError => e
      flash[:error] = "Something went wrong interacting with NeLS, please try again later (#{e.class.name})"
    end

    redirect_to nels_path
  end

  def create_folder
    begin
      folder_name = params[:new_folder]
      if folder_name.include?(' ')
        respond_to do |format|
          format.json { render json:{error: 'Folder names containing spaces are not allowed' }, status: :not_acceptable }
        end
      else
        @rest_client.create_folder(params[:project_id].to_i, params[:dataset_id].to_i, params[:file_path], folder_name)
        respond_to do |format|
          format.all { render json:{success: true} }
        end
      end
    rescue RuntimeError => e
      Rails.logger.error("Error creating folder  #{e.message} - #{e.backtrace.join($/)}")
      respond_to do |format|
        format.json { render json:{error: e.message, exception: e.class.name }, status: :internal_server_error }
      end
    end
  end

  def upload_file
    begin
      filename = params['content_blobs'][0]['data'].original_filename
      if filename.include?(' ')
        respond_to do |format|
          format.json { render json:{error: 'Filenames containing spaces are not allowed' }, status: :not_acceptable }
        end
      else
        data_path = params['content_blobs'][0]['data'].path
        subtype_path = params[:subtype_path] || ''
        @rest_client.upload_file(params[:project_id].to_i, params[:dataset_id].to_i, params[:subtype_name],
                                 subtype_path, filename, data_path)
        respond_to do |format|
          format.all { render json:{success: true} }
        end
      end
    rescue RuntimeError => e
      Rails.logger.error("Error uploading file  #{e.message} - #{e.backtrace.join($/)}")
      respond_to do |format|
        format.json { render json:{error: e.message, exception: e.class.name }, status: :internal_server_error }
      end
    end

  end

  def download_file
    begin
      path_in_subtype = extract_subtype_path(params[:path],params[:project_name], params[:dataset_name], params[:subtype_name], params[:filename])
      filename, path = @rest_client.download_file(params[:project_id].to_i, params[:dataset_id].to_i,
                                                  params[:subtype_name], path_in_subtype, params[:filename])
      respond_to do |format|
        format.json { render json:{filename: filename, file_path: path} }
      end
    rescue RuntimeError, StandardError => e
      respond_to do |format|
        format.json { render json:{error: e.message, exception: e.class.name }, status: :internal_server_error }
      end
    end

  end

  def fetch_file
    filename = params[:filename]
    path = params[:file_path]

    raise Nels::Rest::Client::FetchFileError.new('invalid location') unless path.start_with?('/tmp/nels-download-')
    raise Nels::Rest::Client::FetchFileError.new('temp copy of file doesnt exist') unless File.exist?(path)
    send_file path, filename: filename, disposition: 'attachment'
  end

  def projects
    @projects = @rest_client.projects

    respond_to do |format|
      format.json
    end
  end

  def project
    @project = params[:project]
    @datasets = @rest_client.datasets(@project[:id])
    respond_to do |format|
      format.html { render partial: 'nels/project' }
    end
  end

  def datasets
    @datasets = @rest_client.datasets(params[:id].to_i)
    respond_to do |format|
      format.json
    end
  end

  def dataset
    @dataset = @rest_client.dataset(params[:project_id].to_i, params[:dataset_id].to_i)
    @register_mode = params[:register_mode]
    @project = @rest_client.project(params[:project_id])

    # Populates the "metadata" field for each subtype, indicating if there is associated metadata with it
    @dataset['subtypes'].each_with_index do |subtype, index|
      @dataset['subtypes'][index]['metadata'] =
        @rest_client.check_metadata_exists(params[:project_id].to_i, params[:dataset_id].to_i, subtype['type'])
    end

    respond_to do |format|
      format.html { render partial: 'nels/dataset' }
    end
  end

  def subtype
    @project_id = params[:project_id].to_i
    @dataset_id = params[:dataset_id].to_i
    @dataset = @rest_client.dataset(@project_id, params[:dataset_id].to_i)
    @project = @rest_client.project(@project_id)
    @path = params[:path]
    @subtype_name = params[:subtype]
    @subtype_path = extract_subtype_path(@path, @project['name'], @dataset['name'], @subtype_name)
    @subtype_metadata = @rest_client.check_metadata_exists(@project_id, @dataset_id, @subtype_name)

    @file_list = @rest_client.sbi_storage_list(@project_id, @dataset_id, @path)

    respond_to do |format|
      format.html { render partial: 'nels/subtype' }
    end
  end

  def register
    dataset = @rest_client.dataset(params[:project_id].to_i, params[:dataset_id].to_i)
    url = @rest_client.persistent_url(params[:project_id].to_i, params[:dataset_id].to_i, params[:subtype_name])

    title = [dataset['name'], params[:subtype_name]].reject(&:blank?).join(' - ')

    @data_file = DataFile.new(title: title)
    @content_blob = @data_file.build_content_blob(url: url.chomp)
    @content_blob.save

    session[:uploaded_content_blob_id] = @content_blob.id
    session[:processed_datafile] = @data_file
    session[:processed_assay] = @assay

    redirect_to provide_metadata_data_files_path(project_ids: @assay.project_ids)
  end

  private

  def authorize
    if params[:assay_id]
      find_and_authorize_assay
    elsif current_user.person.projects.any?(&:nels_enabled)
      true
    end
  end

  def extract_subtype_path(full_path, project_name, dataset_name, subtype_name, file_name='')
    root_path = ['Storebioinfo',project_name, dataset_name, subtype_name].join('/')
    full_path.gsub(root_path,"").chomp(file_name).gsub(/^\//,'')
  end

  def find_and_authorize_assay
    @assay = Assay.find(params[:assay_id])

    unless @assay.can_edit?
      flash[:error] = 'You are not authorized to add NeLS data to this assay.'
      redirect_to @assay
      return false
    end

    unless @assay.projects.any?(&:nels_enabled)
      flash[:error] = "This assay is not associated with a NeLS-enabled #{t('project').downcase}."
      redirect_to @assay
      false
    end
  end

  def oauth_client
    @oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                             Seek::Config.nels_client_secret,
                                             nels_oauth_callback_url,
                                             "assay_id:#{params[:assay_id]}")
  end

  def nels_oauth_session
    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    unauthorized_response if !@oauth_session || @oauth_session.expired?
  end

  def rest_client
    @rest_client = Nels::Rest.client_class.new(@oauth_session.access_token)
  end

  def unauthorized_response
    if request.format == :json
      render json: { error: 'Unauthorized',
                     message: 'Attempting to reauthenticate...',
                     url: @oauth_client.authorize_url }, status: :unauthorized
    else
      redirect_to @oauth_client.authorize_url
    end
  end

  def nels_error_response
    render json: { error: 'NeLS API Error',
                   message: 'An error occurred whilst accessing the NeLS API.' }, status: :internal_server_error
  end

  def check_code_present
    unless params[:code]
      flash[:error] = 'Bad callback - No auth code provided.'
      redirect_to root_path
    end
  end

  def check_user_logged_in
    unless current_user
      flash[:error] = 'You must be logged in to access NeLS.'
      redirect_to root_path
    end
  end
end
