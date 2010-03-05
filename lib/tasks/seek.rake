require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'

namespace :seek do

  task(:refresh_controlled_vocabs=>:environment) do
    other_tasks=["culture_growth_types","model_types","model_formats","assay_types","disciplines","organisms","technology_types","recommended_model_environments","measured_items","units","roles","update_first_letters"]
    other_tasks.each do |task|
      Rake::Task[ "seek:#{task}" ].execute      
    end
  end

  #removes any data this is not authorized to viewed by the first User
  task(:remove_private_data=>:environment) do
    sops=Sop.find(:all)
    private_sops=sops.select{|s| !Authorization.is_authorized?("view",nil,s,User.first)}
    puts "#{private_sops.size} private Sops being removed"
    private_sops.each{|s| s.destroy }

    models=Model.find(:all)
    private_models=models.select{|m| !Authorization.is_authorized?("view",nil,m,User.first)}
    puts "#{private_models.size} private Models being removed"
    private_models.each{|m| m.destroy }

    data=DataFile.find(:all)
    private_data=data.select{|d| !Authorization.is_authorized?("view",nil,d,User.first)}
    puts "#{private_data.size} private Data files being removed"
    private_data.each{|d| d.destroy }

  end

  task(:list_dubious_tags=>:environment) do
    revert_fixtures_identify
    tags=Tag.find(:all)
    dubious=tags.select{|tag| dubious_tag?(tag.name)}
    dubious.each{|tag| puts "#{tag.id}\t#{tag.name}" }
  end

  task(:culture_growth_types=>:environment) do
    revert_fixtures_identify
    CultureGrowthType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "culture_growth_types")
  end

  task(:model_types=>:environment) do
    revert_fixtures_identify
    ModelType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "model_types")
  end

  task(:model_formats=>:environment) do
    revert_fixtures_identify
    ModelFormat.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "model_formats")
  end

  task(:assay_types=>:environment) do
    revert_fixtures_identify
    AssayType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "assay_types")
  end

  task(:disciplines=>:environment) do
    revert_fixtures_identify
    Discipline.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "disciplines")
  end

  task(:organisms=>:environment) do
    revert_fixtures_identify
    Organism.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "organisms")
  end

  task(:technology_types=>:environment) do
    revert_fixtures_identify
    TechnologyType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "technology_types")
  end

  task(:recommended_model_environments=>:environment) do
    revert_fixtures_identify
    RecommendedModelEnvironment.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "recommended_model_environments")
  end

  task(:measured_items=>:environment) do
    revert_fixtures_identify
    MeasuredItem.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "measured_items")
  end

  task(:units=>:environment) do
    revert_fixtures_identify
    Unit.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "units")
  end

  task(:roles=>:environment) do
    revert_fixtures_identify
    Role.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "roles")
  end
  
  task(:assay_classes=>:environment) do
    revert_fixtures_identify
    AssayClass.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "assay_classes")
  end

  desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
  task :xmi => :environment do
    require 'lib/uml_dumper.rb'
    File.open("doc/data_models/schema.xmi", "w") do |file|
      ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Done. Schema XMI created as doc/data_models/schema.xmi."
  end

  task :update_first_letters => :environment do
    (Person.find(:all)|Project.find(:all)|Institution.find(:all)|Model.find(:all)|DataFile.find(:all)|Sop.find(:all)|Assay.find(:all)|Study.find(:all)|Investigation.find(:all)).each do |p|
      #suppress the timestamps being recorded.
      class << p
        def record_timestamps
          false
        end
      end
      p.save #forces the first letter to be updated
      puts "Updated for #{p.class.name} : #{p.id}"
    end
  end

  #a 1 shot task to update the creators field for Asset retrospectively for contributors
  task :update_creators => :environment do
    Asset.find(:all).each do |asset|      
      if (asset.creators.empty? && !asset.contributor.nil?)
        class << asset
          def record_timestamps
            false
          end
        end
        asset.creators << asset.contributor.person
        asset.save!
        puts "Added creator for Asset: #{asset.id}"
      end
    end
  end
  
  #Task to add default assay_class (1 - Experimental Assay) to those without one
  task :update_assay_classes => :environment do
    default_assay_class = AssayClass.find(1)
    unless default_assay_class.nil?
      count = 0
      Assay.all.each do |assay|
        if assay.assay_class.nil?
          assay.assay_class = default_assay_class
          assay.save
          count += 1
        end
      end
      puts "Done - #{count} assay classes modified."
    else
      puts "Couldn't find default assay class (ID:1)!"
    end
  end

  private

  #returns true if the tag is over 30 chars long, or contains colons, semicolons, comma's or forward slash
  def dubious_tag?(tag)
    tag.length>30 || [";",",",":","/"].detect{|c| tag.include?(c)}
  end

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    def Fixtures.identify(label)
      label.to_s.hash.abs
    end
  end

end