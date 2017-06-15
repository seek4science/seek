class NelsController < ApplicationController

  before_filter :oauth_client
  before_filter :nels_oauth_session, except: :callback
  before_filter :rest_client, except: :callback

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(access_token: hash['access_token'], expires_in: 2.hours)

    redirect_to nels_browser_path
  end

  def browser
    respond_to do |format|
      format.html { render layout: 'nels' }
    end
  end

  def projects
    @projects = @rest_client.projects
    puts @projects.inspect

    respond_to do |format|
      format.json
    end
  end

  def datasets
    @datasets = @rest_client.datasets(params[:id].to_i)
    puts @datasets.inspect

    respond_to do |format|
      format.json
    end
  end

  def subtypes
    @dataset = @rest_client.dataset(params[:project_id].to_i, params[:id].to_i)

    respond_to do |format|
      format.json
    end
  end

  private

  def oauth_client
    @oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                             Seek::Config.nels_client_secret,
                                             nels_oauth_callback_url)
  end

  def nels_oauth_session
    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    if !@oauth_session || @oauth_session.expired?
      redirect_to @oauth_client.authorize_url
    end
  end

  def rest_client
    @rest_client = Nels::Rest::Client.new(@oauth_session.access_token)
  end

end
