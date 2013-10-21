
module TavernaPlayer
  class Run < ActiveRecord::Base
    # Do not remove the next line.
    include TavernaPlayer::Concerns::Models::Run
    # Extend the Run model here.

    belongs_to :sweep

    belongs_to :user

    attr_accessible :user_id
  end
end
