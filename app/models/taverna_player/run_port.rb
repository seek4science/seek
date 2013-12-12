module TavernaPlayer
  class RunPort < ActiveRecord::Base
    include TavernaPlayer::Concerns::Models::RunPort
  end

  class RunPort::Input < RunPort
    include TavernaPlayer::Concerns::Models::Input
  end

  class RunPort::Output < RunPort
    include TavernaPlayer::Concerns::Models::Output
  end
end