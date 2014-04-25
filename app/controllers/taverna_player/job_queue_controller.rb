
module TavernaPlayer
  class JobQueueController < TavernaPlayer::ApplicationController
    before_filter :login_required
    before_filter :is_user_admin_auth

    include TavernaPlayer::Concerns::Controllers::JobQueueController
  end
end
