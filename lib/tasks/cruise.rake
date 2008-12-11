require 'rubygems'
require 'rake'


desc "task for cruise control"
task :cruise => :"db:migrate" do
  ENV['RAILS_ENV'] = 'test'
  
  if not File.exists?(Dir.pwd+"/config/database.yml")
    File.copy(Dir.pwd+"/config/database.cc.yml", Dir.pwd+"/config/database.yml")
  end
  
  Rake::Task["db:test:purge"].invoke
  Rake::Task["db:test:prepare"].invoke
  Rake::Task["test"].invoke
  
end