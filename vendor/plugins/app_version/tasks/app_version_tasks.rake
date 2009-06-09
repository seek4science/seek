namespace :app do
  require 'erb'
  
  desc 'Report the application version.'
  task :version do
    require File.join(File.dirname(__FILE__), "../lib/app_version.rb")
    puts "Application version: " << Version.load("#{RAILS_ROOT}/config/version.yml").to_s
  end

  desc 'Configure for initial install.'
  task :install do
    require File.join(File.dirname(__FILE__), "../install.rb")
  end

  desc 'Clean up prior to removal.'
  task :uninstall do
    require File.join(File.dirname(__FILE__), "../uninstall.rb")
  end

  desc 'Render the version.yml from its template.'
  task :render do
    template = File.read(RAILS_ROOT + "/lib/templates/version.yml.erb")
    result   = ERB.new(template).result(binding)
    File.open(RAILS_ROOT + "/config/version.yml", 'w') { |f| f.write(result)}
  end
end
