require 'rubygems'
require 'rake'
require 'fileutils'
require 'bundler'


desc "task for cruise control"
task :cruise do
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
  
end
