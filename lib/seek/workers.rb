require 'delayed/command'

# module for handling interaction with delayed job workers
module Seek
  module Workers
    def self.start
      invoke('start')
    end

    def self.invoke(action)
      commands = create_commands(action)
      daemonize_commands(commands)
    end

    def self.daemonize_commands(commands)
      commands.map { |command| Delayed::Command.new(command.split).daemonize }
    end

    def self.create_commands(action)
      commands = []

      active_queues.each_index  do |index, queue_name|
        commands << command(queue_name, index+1, 1, action)
      end
      commands
    end

    def self.active_queues
      queues = [QueueNames::DEFAULT]
      queues << QueueNames::MAILERS
      queues << QueueNames::AUTH_LOOKUP if Seek::Config.auth_lookup_enabled
      queues << QueueNames::REMOTE_CONTENT if Seek::Config.cache_remote_files
      queues << QueueNames::SAMPLES if Seek::Config.samples_enabled
      queues << QueueNames::INDEXING if Seek::Config.solr_enabled
      queues << QueueNames::TEMPLATES if Seek::Config.isa_json_compliance_enabled
      queues << QueueNames::DATAFILES if Seek::Config.data_files_enabled
      queues
    end

    def self.stop
      invoke 'stop'
    end

    def self.status
      daemonize_commands(['status'])
    end

    def self.restart
      invoke 'restart'
    end

    def self.command(queue_name, index, number_of_workers, action)
      "--queue=#{queue_name} -i #{index} -n #{number_of_workers} #{action}"
    end
  end
end
