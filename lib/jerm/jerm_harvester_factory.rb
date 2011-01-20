module Jerm
  class JermHarvesterFactory
    
    def initialize
      discover_harvesters
    end    
    
    def construct_project_harvester project_name,root_uri,uname,pwd
      #removes hyphens from project name
      clean_project_name=project_name.gsub("-","")
      discover_harvesters if @@harvesters.nil?
      
      harvester_class=@@harvesters.find do |h|
        h.name.downcase.start_with?("jerm::"+clean_project_name.downcase)
      end
      raise Exception.new("Unable to find Harvester for project #{project_name}") if harvester_class.nil?
      return harvester_class.new(root_uri,uname,pwd)
    end
        
    #find class for all the harversters found in lib/jerm
    def discover_harvesters
      Dir.chdir(File.join(RAILS_ROOT, "lib/jerm")) do
        Dir.glob("*harvester.rb").each do |f|
         ("jerm/" + f.gsub(/.rb/, '')).camelize.constantize
        end
      end
      harvesters=[]
      ObjectSpace.each_object(Class) do |c|
        harvesters << c if c < Jerm::Harvester
      end
      
      @@harvesters=harvesters
    end
    
  end
end