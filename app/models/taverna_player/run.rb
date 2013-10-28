
module TavernaPlayer
  class Run < ActiveRecord::Base
    # Do not remove the next line.
    include TavernaPlayer::Concerns::Models::Run
    # Extend the Run model here.

    validates_presence_of :name

    belongs_to :sweep

    belongs_to :user

    attr_accessible :user_id

    acts_as_authorized
    belongs_to :policy
    scope :default_order, order('created_at')

    def self.by_owner(uid)
      where(:contributor_id => uid, :contributor_type => "User")
    end

    # Runs should be private by default
    def default_policy
      puts
      Policy.private_policy
    end
  end
end
