class NelsController < ApplicationController

  before_filter :nels_oauth_session, only: :browser

  def callback
    client = Nels::Oauth2::Client.new('seek_pilot', '', nels_oauth_callback_url)
    hash = client.get_token(params[:code])

    oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first_or_initialize
    oauth_session.update_attributes(
        access_token: hash['access_token'],
        expires_in: 6.hours,
    )

    redirect_to nels_browser_path
  end

  def browser
    c = Nels::Rest::Client.new(@oauth_session.access_token)
    render text: c.user_info.inspect
  end

  private

  def nels_oauth_session
    @nels_client = Nels::Oauth2::Client.new('seek_pilot', '', nels_oauth_callback_url)

    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    if !@oauth_session || @oauth_session.expired?
      redirect_to @nels_client.authorize_url
    end
  end

end
