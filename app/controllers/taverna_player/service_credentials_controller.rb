
module TavernaPlayer
  class ServiceCredentialsController < TavernaPlayer::ApplicationController
    before_filter :login_required
    before_filter :is_user_admin_auth

    include TavernaPlayer::Concerns::Controllers::ServiceCredentialsController
  end
end
