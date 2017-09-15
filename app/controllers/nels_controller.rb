class NelsController < ApplicationController

  before_filter :oauth_client
  before_filter :nels_oauth_session, except: :callback
  before_filter :rest_client, except: :callback

  rescue_from RestClient::Unauthorized, :with => :unauthorized_response

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(access_token: hash['access_token'], expires_in: 2.hours)
    unless (match = params[:state].match(/assay_id:(\d+)/)).nil?
      params[:assay_id] = match[1].to_i
    end

    redirect_to nels_browser_path(assay_id: params[:assay_id])
  end

  def browser
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

    redirect_to new_data_file_path(anchor: 'remote-url',
                                   'data_file[title]' => title,
                                   data_url: url,
                                   assay_ids: [params[:assay_id]],
                                   project_ids: Assay.find(params[:assay_id]).project_ids)
  end

  private

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
    client_class = Rails.env.test? ? Nels::Rest::Client : Nels::Rest::DummyClient
    @rest_client = client_class.new(@oauth_session.access_token)
  end

  def unauthorized_response
    if action_name == 'browser'
      redirect_to @oauth_client.authorize_url
    else
      render json: { error: 'Unauthorized',
                     message: 'Attempting to reauthenticate...',
                     url: @oauth_client.authorize_url }, status: :unauthorized
    end
  end

end
