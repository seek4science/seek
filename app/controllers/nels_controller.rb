class NelsController < ApplicationController

  before_filter :nels_oauth_session, only: :nels_page

  def nels_callback
    oauth_session = OauthSession.find_or_initialize_by_user_id_and_provider(current_user.id, 'NeLS')
    oauth_session.update_attributes(
        access_token: hash['access_token'],
        expires_in: 6.hours,
    )

    redirect_to nels_page_path
  end

  def nels_page
    c = Nels::Rest::Client.new(@oauth_session.access_token)
    render text: c.user_info.inspect
  end

  private

  def nels_oauth_session
    @nels_client = Nels::Oauth2::Client.new('seek_pilot', seek_nels_url)

    @oauth_session = current_user.oauth_sessions.where(provider: 'NeLS').first
    if !@oauth_session || @oauth_session.expired?
      redirect_to @nels_client.authorize_url
    end
  end

end
