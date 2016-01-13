module Zenodo
  module Oauth2
    module SessionHelper

      def zenodo_oauth_client
        @zenodo_oauth_client = Zenodo::Oauth2::Client.new(
            Seek::Config.zenodo_client_id,
            Seek::Config.zenodo_client_secret,
            zenodo_oauth_callback_url,
            Seek::Config.zenodo_oauth_url
        )
      end

      def zenodo_oauth_session
        @oauth_session = current_user.oauth_sessions.where(provider: 'Zenodo').first
        if @oauth_session
          if @oauth_session.expired?
            begin
              hash = @zenodo_oauth_client.refresh(oauth_session.refresh_token)
              @oauth_session.update_attributes(
                  access_token: hash['access_token'],
                  expires_in: hash['expires_in'],
                  refresh_token: hash['refresh_token']
              )
            rescue
              redirect_to @zenodo_oauth_client.authorize_url(request.original_url)
            end
          end
        else
          redirect_to @zenodo_oauth_client.authorize_url(request.original_url)
        end
      end

    end
  end
end
