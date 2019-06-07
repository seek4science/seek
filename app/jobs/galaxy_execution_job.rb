require 'pty'

class GalaxyExecutionJob < SeekJob
  attr_reader :data_file_id, :workflow_id, :execution_id, :study_id, :history_name, :assay_description

  def initialize(data_file,workflow,execution_id, study_id, history_name, assay_description)
    @data_file_id = data_file.id
    @workflow_id = workflow.id
    @execution_id = execution_id
    @study_id = study_id
    @history_name = history_name
    @assay_description = assay_description
  end

  def perform_job(items)
    chunks = items.each_slice(2).to_a

    chunks.each do |chunk|
      puts "#{chunk.count} execution items to process"
      threads = []
      chunk.each do |item|
        threads << Thread.new do
          item.update_attribute(:status, GalaxyExecutionQueueItem::RUNNING)
          begin
            execute_galaxy_script(item)
          rescue RuntimeError=>e
            puts "Unexpected runtime error #{e.message}"
          end

          if item.error?
            item.update_attribute(:status, GalaxyExecutionQueueItem::FAILED)
          else
            if item.outputs
              item.update_attribute(:output_json, JSON.dump(item.outputs))
            end

            item.update_attribute(:status, GalaxyExecutionQueueItem::CREATING_RESULTS)

            data_files = register_data_files(item)
            assay = register_assay(item, data_files)

            item.update_attribute(:status, GalaxyExecutionQueueItem::FINISHED)
          end
        end
        sleep(2)
      end

      threads.each(&:join)

    end
  end

  def gather_items
    [queued_items]
  end

  def timelimit
    1.day
  end

  def follow_on_job?
    queued_items.any?
  end

  def follow_on_delay
    0.5.second
  end

  private

  def queued_items
    GalaxyExecutionQueueItem.where(data_file_id: data_file_id, status: GalaxyExecutionQueueItem::QUEUED, execution_id: execution_id)
  end

  def execute_galaxy_script(item)
    @outputs = []
    cmd = command(item)
    puts "command = #{cmd}"
    begin
      PTY.spawn( cmd ) do |stdout, stdin, pid|
        begin
          # Do stuff with the output here. Just printing to show it works
          stdout.each { |line| handle_response(line,item) }
        rescue Errno::EIO
          #puts "Errno:EIO error found"
        end
      end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end

  def handle_response(line,item)
    puts line
    begin
      j = JSON.parse(line)
      msg = j['status']
      item.update_attribute(:current_status,msg)
      if j['data']
        if j['data']['history_id']
          item.update_attribute(:history_id,j['data']['history_id'])
        end
        if steps = j['data']['step_status']
          item.update_attribute(:step_json,JSON.dump(steps))
        end
        if j['data']['step'] && j['data']['output']
          item.outputs ||= []
          item.outputs << j['data']
          puts "output added - #{item.outputs.count} #{j['data'].inspect}"
        end
        if j['data']['error']
          item.update_attribute(:error,j['data']['error'])
        end
      end
    rescue JSON::ParserError
      puts "not JSON, ignoring: #{line}"
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
    json['workflow_id'] = workflow.galaxy_id
    json['history_name'] = @history_name + "-" + item.sample.title
    json['folder_name'] = 'Stuart script testing'
    json['input_data']={}
    json['input_data']['forward']=item.sample.get_attribute('fastq_forward')
    json['input_data']['reverse']=item.sample.get_attribute('fastq_reverse')
    json['downloads'] = downloads(item)
    JSON(json).to_s
  end

  def downloads(item)
    hash = {}
    CSV.parse(item.output_data).each do |row|
      step_label = row[0].strip
      hash[step_label] ||= []
      hash[step_label] << {"name":row[1].strip, "filename_postfix":row[2].strip}
    end
    puts "hash = #{hash.inspect}"
    hash
  end

  def workflow
    Workflow.find(workflow_id)
  end

  def study
    Study.find(study_id)
  end

  def register_data_files(item)
    projects = study.projects
    item.outputs.collect do |output|
      step = output['step']
      output_name = output['output']['name']
      filepath = output['output']['filepath']
      data_file_name = "#{workflow.title} - #{step} - #{output_name}"

      data_file = DataFile.new(title: data_file_name, contributor:item.person, projects:projects)
      data_file.policy = study.policy.deep_copy
      data_file.license = projects.last.default_license
      content_blob = data_file.build_content_blob(tmp_io_object: File.open(filepath))
      content_blob.original_filename=filepath.split("/").last

      disable_authorization_checks do
        content_blob.save!
        data_file.save!
      end

      data_file

    end
  end

  def execution_url
    "#{Seek::Config.site_base_host}/data_files/#{data_file_id}/galaxy_analysis_progress?execution_id=#{execution_id}"
  end

  def register_assay(item, data_files)
    projects = study.projects
    assay_name = "#{history_name} - #{workflow.title} - #{item.sample.title}"

    assay = Assay.new(title:assay_name, study:study, contributor:item.person, assay_class:AssayClass.experimental)
    data_files.each do |df|
      assay.assay_assets.build(asset:df, direction:AssayAsset::Direction::OUTGOING)
    end
    assay.assay_assets.build(asset:item.sample, direction:AssayAsset::Direction::INCOMING)
    assay.assay_assets.build(asset:workflow)
    assay.policy = study.policy.deep_copy
    assay.description = "#{@assay_description}
History: #{item.history_url}
Execution #{execution_url}"

    disable_authorization_checks do
      assay.save!
    end
    item.update_attribute(:assay_id, assay.id)
    assay
  end

end
