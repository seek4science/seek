module Zenodo
  module Oauth2
    class CallbacksController < ApplicationController

      def callback
        client = Zenodo::Oauth2::Client.new(
            Seek::Config.zenodo_client_id,
            Seek::Config.zenodo_client_secret,
            zenodo_oauth_callback_url,
            Seek::Config.zenodo_oauth_url
        )

        hash = client.get_token(params[:code])
        oauth_session = OauthSession.find_or_initialize_by_user_id_and_provider(current_user.id, 'Zenodo')
        oauth_session.update_attributes(
            access_token: hash['access_token'],
            expires_in: hash['expires_in'],
            refresh_token: hash['refresh_token']
        )

        redirect_to params[:state]
      end

    end
  end
end
