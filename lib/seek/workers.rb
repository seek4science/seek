require 'delayed/command'

# module for handling interaction with delayed job workers
module Seek
  module Workers
    def self.start(number_of_taverna_workers = 0, action = 'start')
      number_of_taverna_workers = 0 unless Seek::Config.workflows_enabled

      commands = create_commands(number_of_taverna_workers, action)

      daemonize_commands(commands)
    end

    def self.daemonize_commands(commands)
      commands.map { |command| Delayed::Command.new(command.split).daemonize }
    end

    def self.create_commands(number_of_taverna_workers, action)
      identifier = 0
      commands = []
      queues = [Delayed::Worker.default_queue_name]
      queues << QueueNames::AUTH_LOOKUP if Seek::Config.auth_lookup_enabled
      queues << QueueNames::REMOTE_CONTENT if Seek::Config.cache_remote_files
      queues << QueueNames::SAMPLES if Seek::Config.samples_enabled
      queues << TavernaPlayer.job_queue_name if number_of_taverna_workers > 0
      queues.each do |queue_name|
        number = (queue_name == TavernaPlayer.job_queue_name) ? number_of_taverna_workers : 1
        commands << command(queue_name, identifier, number, action)
        identifier += 1
      end
      commands
    end

    def self.stop
      Delayed::Command.new(['stop']).daemonize
    end

    def self.status
      Delayed::Command.new(['status']).daemonize
    end

    def self.restart(number = 0)
      start(number, 'restart')
    end

    def self.start_data_file_auth_lookup_worker(number = 1)
      commands = [command(QueueNames::AUTH_LOOKUP, 0, number, 'start')]
      daemonize_commands(commands)
    end

    def self.command(queue_name, identifier, number_of_workers, action)
      "--queue=#{queue_name} -i #{identifier} -n #{number_of_workers} #{action}"
    end
  end
end
