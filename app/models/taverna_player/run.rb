
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

    after_create :fix_run_input_ports_mime_types
    before_create :inherit_sweep_policy

    validates_presence_of :name

    attr_accessible :project_ids

    belongs_to :sweep

    scope :default_order, order('created_at')

    def self.by_owner(uid)
      where(:contributor_id => uid, :contributor_type => "User")
    end

    # Runs should be private by default
    def default_policy
      if self.embedded
        Policy.public_policy
      else
        Policy.private_policy
      end
    end

    def title
      name
    end

    # Needed to show the "download" option in the sharing/permissions form
    def is_downloadable?
      true
    end

    def using_sweep_policy?
      !sweep.nil? && (policy_id == sweep.policy_id)
    end

    def result_outputs
      port_names = workflow.result_output_ports.map { |o| o.name }
      outputs.select {|o| port_names.include?(o.name) }
    end

    def error_log_outputs
      port_names = workflow.error_log_output_ports.map { |o| o.name }
      outputs.select {|o| port_names.include?(o.name) }
    end

    def data_inputs
      port_names = workflow.data_input_ports.map { |i| i.name }
      inputs.select {|i| port_names.include?(i.name) }
    end

    def parameter_inputs
      port_names = workflow.parameter_input_ports.map { |i| i.name }
      inputs.select {|i| port_names.include?(i.name) }
    end

    def sweepable?
      workflow.sweepable_from_run? && sweep_id.blank?
    end

    private

    alias_method :old_default_contributor, :default_contributor

    def default_contributor
      if self.embedded
        User.guest
      else
        old_default_contributor
      end
    end

    def fix_run_input_ports_mime_types
      self.inputs.each do |input|
        input.metadata = {:size => nil, :type => ''} if input.metadata.nil?
        port = self.workflow.input_ports.detect { |i| i.name == input.name }
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

    def inherit_sweep_policy
      self.policy_id = sweep.policy_id unless sweep.nil?
    end
  end
end
