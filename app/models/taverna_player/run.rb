
module TavernaPlayer
  class Run < ActiveRecord::Base
    # Do not remove the next line.
    include TavernaPlayer::Concerns::Models::Run

    belongs_to :sweep

    attr_accessor :user_id # temporary hack until we add user_id column
    # Extend the Run model here.
  end
end
