require 'rubygems'
require 'rake'
require 'fileutils'


desc "task for cruise control"
task :cruise do
  ENV['RAILS_ENV'] = 'test'
  
  if !File.exists?(Dir.pwd+"/config/database.yml")
    FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")
  else
    Rake::Task["db:drop"].invoke
  end
  
  Rake::Task["db:create"].invoke
  Rake::Task["db:test:load"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["seek:repop_cv"].invoke
  Rake::Task["test"].invoke
  
end
