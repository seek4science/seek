require 'zip'

class Sweep < ActiveRecord::Base
  acts_as_asset

  has_many :runs, :class_name => 'TavernaPlayer::Run', :dependent => :destroy
  belongs_to :workflow

  accepts_nested_attributes_for :runs

  # attr_accessible :contributor_id, :workflow_id, :name, :runs_attributes, :workflow_version

  before_destroy :cancel

  alias_attribute :title, :name

  def cancel
    runs.each do |run|
      run.cancel unless run.finished?
    end
  end

  def cancelled?
    runs.all? { |run| run.cancelled? }
  end

  def finished?
    runs.all? { |run| run.finished? }
  end

  def running?
    runs.any? { |run| run.running? }
  end

  def complete?
    runs.all? { |run| run.complete? }
  end

  def state
    if running?
      'running'
    elsif finished?
      'finished'
    elsif cancelled?
      'cancelled'
    else
      'pending'
    end
  end

  def self.by_owner(uid)
    where(:contributor_id => uid)
  end

  def build_zip(output_list)
    unique_id = output_list.map {|o| o.id}.hash.to_s(16).tr('-','0')
    path = "#{Rails.root}/tmp/#{name.parameterize('_')}_results_#{unique_id}.zip"

    unless File.exists?(path)
      Zip::File.open(path, Zip::File::CREATE) do |zip_file|
        output_list.group_by {|o| o.name}.each do |output_name, outputs|
          output_dir_name = output_name
          zip_file.mkdir(output_dir_name) # Make folder for outputs
          outputs.each do |output|
            run_dir_name = "#{output_dir_name}/#{output.run.name}"
            zip_file.mkdir(run_dir_name) # Make subfolder for each run in the sweep
            zip_file.get_output_stream("#{run_dir_name}/#{output.filename}") do |f|
              f.write(output.value)
            end
          end
        end
      end
    end

    path
  end

  # Sweeps should be private by default
  def default_policy
    Policy.private_policy
  end

  def executed_workflow
    workflow.find_version(workflow_version)
  end

end
