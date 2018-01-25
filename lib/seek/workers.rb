require 'delayed/command'

# module for handling interaction with delayed job workers
module Seek
  module Workers
    # TODO: Come back to this when removing workflows
    def self.start(number_of_taverna_workers = 0, action = 'start')
      @identifier = 0
      number_of_taverna_workers = 0

      commands = create_commands(number_of_taverna_workers, action)

      daemonize_commands(commands)
    end

    def self.daemonize_commands(commands)
      commands.map { |command| Delayed::Command.new(command.split).daemonize }
    end

    def self.create_commands(number_of_taverna_workers, action)
      commands = []
      queues = [QueueNames::DEFAULT]
      queues << QueueNames::AUTH_LOOKUP if Seek::Config.auth_lookup_enabled
      queues << QueueNames::REMOTE_CONTENT if Seek::Config.cache_remote_files
      queues << QueueNames::SAMPLES if Seek::Config.samples_enabled

      queues.each do |queue_name|
        commands << command(queue_name, 1, action)
      end
      commands
    end

    def self.stop
      daemonize_commands(['stop'])
    end

    def self.status
      daemonize_commands(['status'])
    end

    def self.restart(number = 0)
      start(number, 'restart')
    end

    def self.start_data_file_auth_lookup_worker(number = 1)
      @identifier = 0
      commands = [command(QueueNames::AUTH_LOOKUP, number, 'start')]
      daemonize_commands(commands)
    end

    def self.command(queue_name, number_of_workers, action)
      "--queue=#{queue_name} -i #{@identifier += 1} -n #{number_of_workers} #{action}"
    end
  end
end
