
module TavernaPlayer
  class Run < ActiveRecord::Base
    # This line has to go at the top to make sure the projects HABTM relationship is defined before the callbacks
    #  provided by TavernaPlayer (specifically after_create :enqueue). If not, associations to Projects aren't
    #  automatically created after the Run is saved.
    include ProjectCompat

    # Do not remove the next line.
    include TavernaPlayer::Concerns::Models::Run
    # Extend the Run model here.
    acts_as_asset

    attr_accessible :workflow_version, :project_ids

    after_create :fix_run_input_ports_mime_types

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

    def fix_run_input_ports_mime_types
      self.inputs.each do |input|
        input.metadata = {:size => nil, :type => ''} if input.metadata.nil?
        port = self.workflow.find_version(self.workflow_version).input_ports.detect { |i| i.name == input.name }
        if port && !port.mime_type.blank?
          if input.depth == 0
            input.metadata[:type] = port.mime_type
          else
            input.metadata[:type] = recursively_set_mime_type(input.metadata[:type], input.depth, port.mime_type)
          end
          input.save
        end
      end
    end
  end
end
