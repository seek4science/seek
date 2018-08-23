# frozen_string_literal: true

require 'rubygems'
require 'rake'

namespace :seek do
  namespace :workers do
    desc 'Start the delayed job workers'
    task start: :environment do
      Seek::Workers.start
    end

    desc 'Stop the delayed job workers'
    task stop: :environment do
      Seek::Workers.stop
    end

    desc 'Get the status of the delayed job workers'
    task status: :environment do
      Seek::Workers.status
    end

    task restart: :environment do
      Seek::Workers.restart
    end
  end
end
