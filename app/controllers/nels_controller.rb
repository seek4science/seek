class NelsController < ApplicationController

  before_filter :oauth_client
  before_filter :nels_oauth_session, only: :browser

  def callback
    hash = @oauth_client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(access_token: hash['access_token'], expires_in: 6.hours)

    redirect_to nels_browser_path
  end

  def browser
    @rest_client = Nels::Rest::Client.new(@oauth_session.access_token)
    render text: { user: @rest_client.user_info, projects: @rest_client.projects.inspect}.inspect
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

end
