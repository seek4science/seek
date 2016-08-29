require 'rubygems'
require 'rake'
require 'fileutils'
require 'bundler'
#require 'rspec/core/rake_task'

"Cruise task for running with .rvm via ./script/build-cruise.sh"
task :cruise do |t,args|
  FileUtils.copy(Dir.pwd+"/test/database.cc.yml", Dir.pwd+"/config/database.yml")

  begin
    Rake::Task["db:drop:all"].invoke
  rescue Exception => e
    puts "Error dropping the database, probably it doesn't exist:#{e.message}"
  end

  Rake::Task["db:create:all"].invoke
  Rake::Task["db:setup"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["test"].invoke

  RSpec::Core::RakeTask.new(:spec)
  Rake::Task["spec"].invoke
end


