require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_units
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end


  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

  desc "add more time units: day, week, month, year"
  task :update_units => :environment do
    unless Unit.time_units.count == 7
      #update the order of some current units before adding new units
      units = Unit.all.select{|u| u.order > 23}
      units.each do |u|
        u.order += 4
        u.save
      end
      #insert day, week, month, year
      [['d',24],['wk',25],['mo',26],['yr',27]].each do |u|
        Unit.create(:symbol => u[0], :order => u[1], :comment => 'time')
      end
    end
    time_units = Unit.time_units.sort_by(&:order)
    if time_units.count == 7
      time_units[0].title = 'second'
      time_units[0].save
      time_units[1].title = 'minute'
      time_units[1].save
      time_units[2].title = 'hour'
      time_units[2].save
      time_units[3].title = 'day'
      time_units[3].save
      time_units[4].title = 'week'
      time_units[4].save
      time_units[5].title = 'month'
      time_units[5].save
      time_units[6].title = 'year'
      time_units[6].save
    end
  end
end
