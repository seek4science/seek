require 'rubygems'
require 'rake'
require 'fileutils'


desc "task for cruise control"
task :cruise do
  ENV['RAILS_ENV'] = 'test'
  
  if !File.exists?(Dir.pwd+"/config/database.yml")
    FileUtils.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")
  end
  
  Rake::Task["db:drop"].invoke
  Rake::Task["db:create"].invoke
  Rake::Task["db:migrate"].invoke
  Rake::Task["db:test:purge"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["seek:repop_cv"].invoke
  Rake::Task["test"].invoke
  
end
