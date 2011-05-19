require 'rubygems'
require 'rake'
require 'fileutils'
require 'bundler'


desc "task for cruise control"
task :cruise, :run_secondary do |t, args|
  args.with_defaults :run_secondary => true
  run_secondary_signal = 'tmp/run_secondary'
  if args[:run_secondary]
    File.new(run_secondary_signal, 'w') unless File.exists? run_secondary_signal
  else
    File.delete(run_secondary_signal) if File.exists? run_secondary_signal
  end
  RAILS_ENV = ENV['RAILS_ENV'] = 'test'
  
  `bundle install`
  Bundler.setup(:default, :test)
  
  FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")      
  
  begin
	  Rake::Task["db:drop:all"].invoke
  rescue Exception => e
  	puts "Error dropping the database, probably it doesn't exist:#{e.message}"
  end
  
  Rake::Task["db:create:all"].invoke
  Rake::Task["db:test:load"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["seek:refresh_controlled_vocabs"].invoke
  Rake::Task["seek:default_tags"].invoke
  Rake::Task["test"].invoke

  File.delete(run_secondary_signal) if File.exists? run_secondary_signal
end
