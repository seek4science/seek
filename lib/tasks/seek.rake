require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'

namespace :seek do

  task(:assay_types=>:environment) do
    AssayType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "assay_types")
  end

  task(:disciplines=>:environment) do
    Discipline.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "disciplines")
  end

  task(:organisms=>:environment) do
    Organism.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "organisms")
  end

  task(:technology_types=>:environment) do
    TechnologyType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "technology_types")
  end

  task(:recommended_model_environments=>:environment) do
    RecommendedModelEnvironment.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "recommended_model_environments")
  end

  task(:measured_items=>:environment) do
    MeasuredItem.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "measured_items")
  end

  task(:units=>:environment) do
    Unit.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "units")
  end

  task(:roles=>:environment) do
    Role.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "roles")
  end

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