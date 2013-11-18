
module TavernaPlayer
  class Run < ActiveRecord::Base
    # Do not remove the next line.
    include TavernaPlayer::Concerns::Models::Run
    # Extend the Run model here.
    acts_as_asset

    before_validation :set_projects_before_validation
    after_create :set_projects

    validates_presence_of :name

    belongs_to :sweep

    scope :default_order, order('created_at')

    def self.by_owner(uid)
      where(:contributor_id => uid, :contributor_type => "User")
    end

    # Runs should be private by default
    def default_policy
      Policy.private_policy
    end

    def title
      name
    end

    # Needed to show the "download" option in the sharing/permissions form
    def is_downloadable?
      true
    end

    private

    # SEEK moans if projects aren't set before save... but they don't actually get persisted by this method for some reason.
    def set_projects_before_validation
      self.project_ids = contributor.person.projects.map {|p| p.id}
    end

    # This method actually sets the Run's projects after save
    def set_projects
      contributor.person.projects.each do |p|
        self.projects << p
      end
    end
  end
end
