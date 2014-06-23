require 'rubygems'
require 'rake'
require 'delayed/command'

namespace :seek do
  namespace :workers do

    desc "Start the delayed job workers"
    task :start, [:number] => [:environment] do |t, args|
      args.with_defaults(:number => "0")
      number = Seek::Config.workflows_enabled ? args.number.to_i : 0
      commands =
        ["--queue=#{Delayed::Worker.default_queue_name} -i #{number} start"]
      if Seek::Config.auth_lookup_enabled
        commands << "--queue=#{AuthLookupUpdateJob.job_queue_name} -i #{number+1} start"
      end
      if number > 0
        commands << "--queue=#{TavernaPlayer.job_queue_name} -n #{number} start"
      end


      commands.map { |c| puts c;Delayed::Command.new(c.split).daemonize }
    end

    desc "Stop the delayed job workers"
    task :stop => :environment do
      Delayed::Command.new(["stop"]).daemonize
    end

    desc "Get the status of the delayed job workers"
    task :status => :environment do
      Delayed::Command.new(["status"]).daemonize
    end

  end
end
