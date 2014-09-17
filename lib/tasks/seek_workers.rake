require 'rubygems'
require 'rake'

namespace :seek do
  namespace :workers do

    desc "Start the delayed job workers"
    task :start, [:number] => [:environment] do |t, args|
      args.with_defaults(:number => "0")
      number = args.number.to_i
      Seek::Workers.start(number)
    end

    desc "Stop the delayed job workers"
    task :stop => :environment do
      Seek::Workers.stop
    end

    desc "Get the status of the delayed job workers"
    task :status => :environment do
      Seek::Workers.status
    end

    task :restart, [:number] => [:environment] do |t, args|
      args.with_defaults(:number => "0")
      number = args.number.to_i
      Seek::Workers.restart(number)
    end

  end
end
