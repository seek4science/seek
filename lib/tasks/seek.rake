require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'

namespace :seek do

  desc 'updates the md5sum, and makes a local cache, for existing remote assets'
  task(:cache_remote_content_blobs=>:environment) do
    resources = Sop.find(:all)
    resources |= Model.find(:all)
    resources |= DataFile.find(:all)
    resources = resources.select{|r| r.content_blob && r.content_blob.data.nil? && r.content_blob.url && r.project}
    
    resources.each do |res|
      res.cache_remote_content_blob
    end
  end

  desc 'upgrades between 0.6 and 0.7'
  task(:upgrade_live=>:environment) do
    other_tasks=["assay_classes","update_assay_classes","strains","graft_new_assay_types","relationship_types"]
    other_tasks.each do |task|
      Rake::Task[ "seek:#{task}" ].execute
    end
  end

  desc 're-extracts bioportal information about all organisms, overriding the cached details'
  task(:refresh_organism_concepts=>:environment) do
    Organism.all.each do |o|
      o.concept({:refresh=>true})
    end
  end

  task(:rebuild_project_organisms=>:environment) do
    organism_taggings=Tagging.find(:all, :conditions=>['context=? and taggable_id > 0', 'organisms'])
    puts "found #{organism_taggings.size} organism taggings"
    organism_taggings.each do |tagging|
      if tagging.taggable_type == "Project"
        tag=tagging.tag
        project=tagging.taggable
        organism=Organism.find(:first, :conditions=>["title=?", tag.name])
        if organism.nil?
          puts "unable to find organism #{tag.name} required for project #{project.title}"
        else
          puts "adding #{organism.title} to #{project.title} "
          class << project
            def record_timestamps
              false
            end
          end
          project.organisms << organism unless project.organisms.include?(organism)
          project.save!
        end
      else
        puts "Tagging with id #{tagging.id} is not for Project"
      end
    end
  end

  desc 'seeds the database with the controlled vocabularies'
  task(:seed=>:environment) do
    tasks=["refresh_controlled_vocabs","graft_new_assay_types"]
    tasks.each do |task|
      Rake::Task[ "seek:#{task}" ].execute     
    end
  end

  desc 'refreshes, or creates, the standard initial controlled vocublaries'
  task(:refresh_controlled_vocabs=>:environment) do
    other_tasks=["culture_growth_types","model_types","model_formats","assay_types","disciplines","organisms","technology_types","recommended_model_environments","measured_items","units","roles","update_first_letters","assay_classes","relationship_types","strains"]
    other_tasks.each do |task|
      Rake::Task[ "seek:#{task}" ].execute      
    end
  end

  desc 'adds the new modelling assay types and creates a new root'
  task(:graft_new_assay_types=>:environment) do
    experimental=AssayType.find(628957644)

    experimental.title="experimental assay type"
    flux=AssayType.new(:title=>"fluxomics")
    flux.save!
    experimental.children << flux
    experimental.save!

    modelling_assay_type=AssayType.new(:title=>"modelling analysis type")
    modelling_assay_type.save!

    new_root=AssayType.new
    new_root.title="assay types"
    new_root.children << experimental
    new_root.children << modelling_assay_type
    new_root.save!

    new_modelling_types = ["cell cycle","enzymology","gene expression","gene regulatory network","metabolic network","metabolism","signal transduction","translation"]
    new_modelling_types.each do |title|
      a=AssayType.new(:title=>title)
      a.save!
      modelling_assay_type.children << a
    end
    modelling_assay_type.save!

  end

  desc 'removes any data this is not authorized to viewed by the first User'
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

  task(:strains=>:environment) do
    revert_fixtures_identify
    Strain.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "strains")
  end

  task(:culture_growth_types=>:environment) do
    revert_fixtures_identify
    CultureGrowthType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "culture_growth_types")
  end

  task(:relationship_types=>:environment) do
    revert_fixtures_identify
    RelationshipType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data" ), "relationship_types")
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
  
  task :add_publication_policies => :environment do
    count = 0
    Publication.all.each do |pub|
      if pub.asset.policy.nil?
        pub.asset.policy = Policy.create(:name => "publication_policy", :sharing_scope => 3, :access_type => 1, :use_custom_sharing => true)
        count += 1
        pub.asset.save
      end
      
      #Update policy so current authors have manage permissions
      pub.asset.creators.each do |author|
        pub.asset.policy.permissions.clear
        pub.asset.policy.permissions << Permission.create(:contributor => author, :policy => pub.asset.policy, :access_type => 4)
      end      
      #Add contributor
      pub.asset.policy.permissions << Permission.create(:contributor => pub.contributor.person, :policy => pub.asset.policy, :access_type => 4)
    end
    puts "Done - #{count} policies for publications added."
  end

  task :content_stats => :environment do
    me=User.first
    projects = Project.all
    projects.each do |project|
      sops=project.assets.select{|a| a.resource.kind_of?(Sop)}
      models=project.assets.select{|a| a.resource.kind_of?(Model)}
      datafiles=project.assets.select{|a| a.resource.kind_of?(DataFile)}
      publications=project.publications
      people=project.people
      registered_people=people.select{|p| !p.user.nil?}

      sops_size=0
      sops.each do |sop|
        sops_size += sop.resource.content_blob.data.size unless sop.resource.content_blob.data.nil?
      end

      models_size=0
      models.each do |model|
        models_size += model.resource.content_blob.data.size unless model.resource.content_blob.data.nil?
      end

      dfs_size=0
      datafiles.each do |df|
        dfs_size += df.resource.content_blob.data.size unless df.resource.content_blob.data.nil?
      end

      puts "Project: #{project.title}"
      puts "\t SOPs: #{sops.count} (#{sops_size/1048576} Mb - #{sops_size/1024} Kb), that I can see #{sops.select{|s| Authorization.is_authorized?('show',nil,s.resource,me)}.count}"
      puts "\t Models: #{models.count} (#{models_size/1048576} Mb - #{models_size/1024} Kb), that I can see #{models.select{|m| Authorization.is_authorized?('show',nil,m.resource,me)}.count}"
      puts "\t Data: #{datafiles.count} (#{dfs_size/1048576} Mb - #{dfs_size/1024} Kb), that I can see #{datafiles.select{|df| Authorization.is_authorized?('show',nil,df.resource,me)}.count}"
      puts "\t Publications: #{publications.count}"
      puts "\t People: #{people.count}, of which have registered: #{registered_people.count}"
      puts "\t Assays: #{project.assays.count}"
      puts "\t Studies: #{project.studies.count}"
      puts "\n --------------- \n\n"
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
