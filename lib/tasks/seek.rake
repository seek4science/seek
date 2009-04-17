require 'rubygems'
require 'rake'
require 'model_execution'

namespace :seek do
  task(:repop_cv=>:environment) do
    
    File.open('config/expertise.list').each do |item|
      unless item.blank?
        item=item.chomp
        if Person.expertise_counts.find{|tag| tag.name==item}.nil?
          tag=Tag.new(:name=>item)
          taggable=Tagging.new(:tag=>tag, :context=>"expertise",:taggable_type=>"Person")
          taggable.save!
        end
      end
    end

    File.open('config/tools.list').each do |item|
      unless item.blank?
        item=item.chomp
        if Person.tool_counts.find{|tag| tag.name==item}.nil?
          tag=Tag.new(:name=>item)
          taggable=Tagging.new(:tag=>tag, :context=>"tools",:taggable_type=>"Person")
          taggable.save!
        end
      end
    end

    File.open('config/organisms.list').each do |item|
      unless item.blank?
        item=item.chomp
        if Project.organism_counts.find{|tag| tag.name==item}.nil?
          tag=Tag.new(:name=>item)
          taggable=Tagging.new(:tag=>tag, :context=>"organisms",:taggable_type=>"Project")
          taggable.save!
        end
      end
    end

  end

  desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
  task :xmi => :environment do
    require 'lib/uml_dumper.rb'
    File.open("doc/data_models/schema.xmi", "w") do |file|
      ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Done. Schema XMI created as doc/data_models/schema.xmi."
  end
  
end