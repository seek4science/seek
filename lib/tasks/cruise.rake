require 'rubygems'
require 'rake'
require 'fileutils'



desc "task for cruise control"
task :cruise do
  ENV['RAILS_ENV'] = 'test'
  
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
  Rake::Task["test"].invoke
  
end
