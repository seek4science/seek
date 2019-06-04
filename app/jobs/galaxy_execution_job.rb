require 'pty'

class GalaxyExecutionJob < SeekJob
  attr_reader :data_file_id, :workflow_id

  def initialize(data_file,workflow)
    @data_file_id = data_file.id
    @workflow_id = workflow.id
  end

  def perform_job(item)
    item.update_attribute(:status, GalaxyExecutionQueueItem::RUNNING)
    execute_galaxy_script(item)
    item.update_attribute(:status, GalaxyExecutionQueueItem::FINISHED)
  end

  def gather_items
    [GalaxyExecutionQueueItem.where(data_file_id: data_file_id).where(status: GalaxyExecutionQueueItem::QUEUED).first].compact
  end

  def timelimit
    1.day
  end

  def follow_on_job?
    GalaxyExecutionQueueItem.where(data_file_id: data_file_id).where(status: GalaxyExecutionQueueItem::QUEUED).any?
  end

  private

  def execute_galaxy_script(item)
    cmd = command(item)
    begin
      PTY.spawn( cmd ) do |stdout, stdin, pid|
        begin
          # Do stuff with the output here. Just printing to show it works
          stdout.each { |line| print line }
        rescue Errno::EIO
          puts "Errno:EIO error"
        end
      end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end

  end

  def command(item)
    args = command_argument_json(item)
    "python3 #{Rails.root}/script/galaxy.py '#{args}'"
  end

  def command_argument_json(item)
    json = {}
    json['url']=item.person.galaxy_instance
    json['api_key']=item.person.galaxy_api_key
    json['workflow_id']=workflow.galaxy_id
    json['data']={}
    json['data']['forward']=item.sample.get_attribute('fastq_forward')
    json['data']['reverse']=item.sample.get_attribute('fastq_reverse')
    JSON(json).to_s
  end

  def workflow
    Workflow.find(workflow_id)
  end

end