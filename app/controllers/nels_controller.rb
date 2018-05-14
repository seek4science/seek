class NelsController < ApplicationController

  before_filter :project_membership_required, except: :callback
  before_filter :find_and_authorize_assay, except: :callback
  before_filter :oauth_client
  before_filter :nels_oauth_session, except: :callback
  before_filter :rest_client, except: :callback

  rescue_from RestClient::Unauthorized, :with => :unauthorized_response
  rescue_from RestClient::InternalServerError, :with => :nels_error_response

  include Seek::BreadCrumbs

  skip_before_filter :add_breadcrumbs, only: :callback

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(access_token: hash['access_token'], expires_in: 2.hours)
    if (match = params[:state].match(/assay_id:(\d+)/))
      params[:assay_id] = match[1].to_i
      redirect_to assay_nels_path(params[:assay_id])
    elsif (match = params[:state].match(/data_file_id:(\d+)/))
      redirect_to retrieve_nels_sample_metadata_data_file_path(match[1].to_i)
    else
      flash[:error] = "Bad redirect - Missing assay or data file ID from state parameter."
      redirect_to root_path
    end
  end

  def index
    respond_to do |format|
      format.html
    end
  end

  def projects
    @projects = @rest_client.projects

    respond_to do |format|
      format.json
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

    respond_to do |format|
      format.html { render partial: 'nels/dataset' }
    end
  end

  def register
    dataset = @rest_client.dataset(params[:project_id].to_i, params[:dataset_id].to_i)
    url = @rest_client.persistent_url(params[:project_id].to_i, params[:dataset_id].to_i, params[:subtype_name])

    title = [dataset['name'], params[:subtype_name]].reject(&:blank?).join(' - ')

    @content_blob = ContentBlob.create(url: url.chomp)
    @data_file = DataFile.new(title: title)
    @data_file.content_blob = @content_blob

    session[:uploaded_content_blob_id] = @content_blob.id
    session[:processed_datafile] = @data_file
    session[:processed_assay] = @assay

    redirect_to provide_metadata_data_files_path(project_ids: @assay.project_ids)
  end

  private

  def find_and_authorize_assay
    @assay = Assay.find(params[:assay_id])

    unless @assay.can_edit?
      flash[:error] = 'You are not authorized to add NeLS data to this assay.'
      redirect_to @assay
      return false
    end

    unless Seek::Config.nels_enabled
      flash[:error] = 'NeLS integration is not enabled on this SEEK instance.'
      redirect_to @assay
      return false
    end

    unless @assay.projects.any? { |p| p.settings['nels_enabled'] }
      flash[:error] = 'This assay is not associated with a NeLS-enabled project.'
      redirect_to @assay
      return false
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
    client_class = Nels::Rest::Client
    @rest_client = client_class.new(@oauth_session.access_token)
  end

  def unauthorized_response
    if action_name == 'index'
      redirect_to @oauth_client.authorize_url
    else
      render json: { error: 'Unauthorized',
                     message: 'Attempting to reauthenticate...',
                     url: @oauth_client.authorize_url }, status: :unauthorized
    end
  end

  def nels_error_response
      render json: { error: 'NeLS API Error',
                     message: 'An error occurred whilst accessing the NeLS API.' }, status: :internal_server_error
  end

end
