require 'rubygems'
require 'rake'


#Tasks specific to the Translucent project
namespace :transclucent do
    
  desc "Updates peoples meta data with that from the Translucent internal system"
  task(:sync_people=>:environment) do
    p=Project.find_by_name("TRANSLUCENT")
    raise Exception.new("Unable to find translucent project") if p.nil?
    p.decrypt_credentials
    people = Jerm::TranslucentPersonHarvester.start(p.site_root_uri,p.site_password)
    puts "Found #{people.size} people."
    people.each do |person|
      begin
        person.update
      rescue Exception=>e
        puts "------"
        puts "Problem with person, error: #{e.message}"
        puts person.to_s
        puts "------"
      end
      
    end
  end
  
end
