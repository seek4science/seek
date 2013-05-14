require 'rubygems'
require 'rake'
require 'fileutils'
require 'bundler'

def run_in_parallel(cmd, options)
  count = "-n #{options[:count]}" if options[:count]
  executable = 'parallel_test'
  command = "#{executable} --exec '#{cmd}' #{count} #{'--non-parallel' if options[:non_parallel]}"
  abort unless system(command)
end

desc "task for cruise control"
task :cruise do |t, args|
  args.with_defaults :count => 1  #count determines the number of processes that parallel_tests will use

  Rails.env = ENV['RAILS_ENV'] = 'test'

  FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")

  begin
    Rake::Task["parallel:drop"].invoke(args[:count])
  rescue Exception => e
    puts "Error dropping the database, probably it doesn't exist:#{e.message}"
  end

  Rake::Task["db:create"].invoke
  Rake::Task["db:test:load"].invoke
  Rake::Task["seek:seed_testing"].invoke

  (2..args[:count]).each do |db_ndx|
     FileUtils.copy(Dir.pwd+"/db/test.sqlite3", Dir.pwd+"/db/test.sqlite3#{db_ndx}")
  end

  Rake::Task["parallel:test"].invoke(args[:count])
end

"Second cruise task for running with .rvm via ./script/build-cruise.sh"
task :cruise2 do |t,args|
  FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")

  begin
    Rake::Task["db:drop:all"].invoke
  rescue Exception => e
    puts "Error dropping the database, probably it doesn't exist:#{e.message}"
  end

  Rake::Task["db:create:all"].invoke
  Rake::Task["db:test:load"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["seek:seed_testing"].invoke
  Rake::Task["test"].invoke
end
