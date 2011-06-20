require 'rubygems'
require 'rake'
require 'active_record/fixtures'

namespace :seek do

  desc 'an alternative to the doc:seek task'
  task(:docs=>["doc:seek"]) do

  end

  desc 'updates the md5sum, and makes a local cache, for existing remote assets'
  task(:cache_remote_content_blobs=>:environment) do
    resources = Sop.find(:all)
    resources |= Model.find(:all)
    resources |= DataFile.find(:all)
    resources = resources.select { |r| r.content_blob && r.content_blob.data.nil? && r.content_blob.url && r.project }

    resources.each do |res|
      res.cache_remote_content_blob
    end
  end

  desc "adds the default tags"
  task(:default_tags=>:environment) do

    File.open('config/default_data/expertise.list').each do |item|
      unless item.blank?
        item=item.chomp
        create_tag item, "expertise", "Person"
      end
    end

    File.open('config/default_data/tools.list').each do |item|
      unless item.blank?
        item=item.chomp
        create_tag item, "tools", "Person"
      end
    end
  end    

  desc 're-extracts bioportal information about all organisms, overriding the cached details'
  task(:refresh_organism_concepts=>:environment) do
    Organism.all.each do |o|
      o.concept({:refresh=>true})
    end
  end

  desc 'seeds the database with the controlled vocabularies'
  task(:seed=>:environment) do
    tasks=["seed_sqlite","load_help_docs"]
    tasks.each do |task|
      Rake::Task["seek:#{task}"].execute
    end
  end

  desc 'seeds the database without the loading of help document, which is currently not working for SQLITE3 (SYSMO-678)'
  task(:seed_sqlite=>:environment) do
    tasks=["refresh_controlled_vocabs", "default_tags", "graft_new_assay_types"]
    tasks.each do |task|
      Rake::Task["seek:#{task}"].execute
    end
  end

  desc 'adds the new modelling assay types and creates a new root'
  task(:graft_new_assay_types=>:environment) do
    experimental      =AssayType.find(628957644)

    experimental.title="experimental assay type"
    flux              =AssayType.new(:title=>"fluxomics")
    flux.save!
    experimental.children << flux
    experimental.save!

    modelling_assay_type=AssayType.new(:title=>"modelling analysis type")
    modelling_assay_type.save!

    new_root      =AssayType.new
    new_root.title="assay types"
    new_root.children << experimental
    new_root.children << modelling_assay_type
    new_root.save!

    new_modelling_types = ["cell cycle", "enzymology", "gene expression", "gene regulatory network", "metabolic network", "metabolism", "signal transduction", "translation", "protein interations"]
    new_modelling_types.each do |title|
      a=AssayType.new(:title=>title)
      a.save!
      modelling_assay_type.children << a
    end
    modelling_assay_type.save!

  end

  desc 'refreshes, or creates, the standard initial controlled vocublaries'
  task(:refresh_controlled_vocabs=>:environment) do
    other_tasks=["culture_growth_types", "model_types", "model_formats", "assay_types", "disciplines", "organisms", "technology_types", "recommended_model_environments", "measured_items", "units", "roles", "assay_classes", "relationship_types", "strains"]
    other_tasks.each do |task|
      Rake::Task["seek:#{task}"].execute
    end
  end

  desc 'removes any data this is not authorized to viewed by the first User'
  task(:remove_private_data=>:environment) do
    sops        =Sop.find(:all)
    private_sops=sops.select { |s| !s.can_view? User.first }
    puts "#{private_sops.size} private Sops being removed"
    private_sops.each { |s| s.destroy }

    models        =Model.find(:all)
    private_models=models.select { |m| ! m.can_view? User.first }
    puts "#{private_models.size} private Models being removed"
    private_models.each { |m| m.destroy }

    data        =DataFile.find(:all)
    private_data=data.select { |d| !d.can_view? User.first }
    puts "#{private_data.size} private Data files being removed"
    private_data.each { |d| d.destroy }

  end

  task(:strains=>:environment) do
    revert_fixtures_identify
    Strain.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "strains")
  end

  task(:culture_growth_types=>:environment) do
    revert_fixtures_identify
    CultureGrowthType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "culture_growth_types")
  end

  task(:relationship_types=>:environment) do
    revert_fixtures_identify
    RelationshipType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "relationship_types")
  end

  task(:model_types=>:environment) do
    revert_fixtures_identify
    ModelType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "model_types")
  end

  task(:model_formats=>:environment) do
    revert_fixtures_identify
    ModelFormat.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "model_formats")
  end

  task(:assay_types=>:environment) do
    revert_fixtures_identify
    AssayType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "assay_types")
  end

  task(:disciplines=>:environment) do
    revert_fixtures_identify
    Discipline.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "disciplines")
  end

  task(:organisms=>:environment) do
    revert_fixtures_identify
    Organism.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "organisms")
    BioportalConcept.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "bioportal_concepts")
  end

  task(:technology_types=>:environment) do
    revert_fixtures_identify
    TechnologyType.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "technology_types")
  end

  task(:recommended_model_environments=>:environment) do
    revert_fixtures_identify
    RecommendedModelEnvironment.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "recommended_model_environments")
  end

  task(:measured_items=>:environment) do
    revert_fixtures_identify
    MeasuredItem.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "measured_items")
  end

  task(:units=>:environment) do
    revert_fixtures_identify
    Unit.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "units")
  end

  task(:roles=>:environment) do
    revert_fixtures_identify
    Role.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "roles")
  end

  task(:assay_classes=>:environment) do
    revert_fixtures_identify
    AssayClass.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "assay_classes")
  end

   task(:compounds=>:environment) do
    revert_fixtures_identify
    Compound.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "compounds")
  end

  #Update the sharing_scope in the policies table, because of removing CUSTOM_PERMISSIONS_ONLY and ALL_REGISTERED_USERS scopes
  task(:update_sharing_scope=>:environment) do
    # sharing_scope
    private_scope = 0
    custom_permissions_only_scope = 1
    all_sysmo_users_scope = 2
    all_registered_users_scope = 3

    #update  ALL_REGISTERED_USERS to ALL_SYSMO_USERS
    policies = Policy.find(:all, :conditions => ["sharing_scope = ?", all_registered_users_scope])
    unless policies.nil?
      count = 0
      policies.each do |policy|
        policy.sharing_scope = all_sysmo_users_scope
        policy.save
        count += 1
      end
      puts "Done - #{count} policies with ALL_REGISTERED_USERS scope changed to ALL_SYSMO_USERS scope."
    else
      puts "Couldn't find any policies with ALL_REGISTERED_USERS scope"
    end

    #update  CUSTOM_PERMISSIONS_ONLY to PRIVATE
    policies = Policy.find(:all, :conditions => ["sharing_scope = ?", custom_permissions_only_scope])
    unless policies.nil?
      count = 0
      policies.each do |policy|
        policy.sharing_scope = private_scope
        policy.save
        count += 1
      end
      puts "Done - #{count} policies with CUSTOM_PERMISSIONS_ONLY scope changed to PRIVATE scope."
    else
      puts "Couldn't find any policies with CUSTOM_PERMISSIONS_ONLY scope"
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
        pub.asset.policy = Policy.create(:name => "publication_policy", :sharing_scope => 3, :access_type => 1)
        count            += 1
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

  desc "Dumps help documents and attachments/images"
  task :dump_help_docs => :environment do
    format_class = "YamlDb::Helper"
    dir          = 'help_dump_tmp'
    #Clear path
    puts "Clearing existing backup directories"
    FileUtils.rm_r('config/default_data/help', :force => true)
    FileUtils.rm_r('config/default_data/help_images', :force => true)
    FileUtils.rm_r('db/help_dump_tmp/', :force => true)
    #Dump DB
    puts "Dumping database"
    SerializationHelper::Base.new(format_class.constantize).dump_to_dir dump_dir("/#{dir}")
    #Copy relevant yaml files
    puts "Copying files"
    FileUtils.mkdir('config/default_data/help') rescue ()
    FileUtils.copy('db/help_dump_tmp/help_documents.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/help_attachments.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/help_images.yml', 'config/default_data/help/')
    FileUtils.copy('db/help_dump_tmp/db_files.yml', 'config/default_data/help/')
    #Delete everything else
    puts "Cleaning up"
    FileUtils.rm_r('db/help_dump_tmp/')
    #Copy image folder
    puts "Copying images"
    FileUtils.mkdir('public/help_images') rescue ()
    FileUtils.cp_r('public/help_images', 'config/default_data/') rescue ()
  end

  desc "Loads help documents and attachments/images"
  task :load_help_docs => :environment do
    #Checks if directory exists, and that there are docs present    
    help_dir = nil
    continue = false
    continue = !(help_dir = Dir.new("config/default_data/help") rescue ()).nil?
    if help_dir
      continue = !help_dir.entries.empty?
      continue = help_dir.entries.include?("help_documents.yml")
    end
    if continue
      #Clear database
      HelpDocument.destroy_all
      HelpAttachment.destroy_all
      HelpImage.destroy_all
      DbFile.destroy_all
      #Populate database with help docs
      format_class = "YamlDb::Helper"
      dir          = '../config/default_data/help/'
      SerializationHelper::Base.new(format_class.constantize).load_from_dir dump_dir("/#{dir}")
      #Copy images
      FileUtils.cp_r('config/default_data/help_images', 'public/')
      #Destroy irrelevent db_files
      (DbFile.all - HelpAttachment.all.collect { |h| h.db_file }).each { |d| d.destroy }
    else
      puts "Aborted - Couldn't find any help documents in /config/default_data/help/"
    end
  end

  desc "Create rebranded default help documents"
  task :rebrand_help_docs => :environment do
    template = ERB.new File.new("config/rebrand/help_documents.erb").read, nil, "%"
    File.open("config/default_data/help/help_documents.yml", 'w') { |f| f.write template.result(binding) }
  end

  desc "The newer acts-as-taggable-on plugin is case insensitve. Older tags are case sensitive, leading to some odd behaviour. This task resolves the old tags"
  task :resolve_duplicate_tags=>:environment do
    tags=ActsAsTaggableOn::Tag.find :all
    skip_tags = []
    tags.each do |tag|
      unless skip_tags.include? tag
        matching = tags.select{|t| t.name.downcase.strip == tag.name.downcase.strip && t.id != tag.id}
        unless matching.empty?
          matching.each do |m|
            puts "#{m.name}(#{m.id}) - #{tag.name}(#{tag.id})"
            m.taggings.each do |tagging|
              unless tag.taggings.detect{|t| t.context==tagging.context && t.taggable==tagging.taggable}
                puts "Updating tagging #{tagging.id} to point to #{tag.name}:#{tag.id}"
                tagging.tag = tag
                tagging.save!
              else
                puts "Deleting duplicate tagging #{tagging.id}"
                tagging.delete
              end
            end
            m.delete
            skip_tags << m  
          end
        end
      end
    end
  end

  desc "Overwrite footer layouts with generic, rebranded alternatives"
  task :rebrand_layouts do
    dir = 'config/rebrand/'
    #TODO: Change to select everything in config/rebrand/ except for help_documents.erb
    FileUtils.cp FileList["#{dir}/*"].exclude("#{dir}/help_documents.erb"), 'app/views/layouts/'
  end

  desc "Replace Sysmo specific files with rebranded alternatives"
  task :rebrand => [:rebrand_help_docs, :rebrand_layouts]

  desc "Generates UUIDs for all items that don't have them"
  task :generate_uuids => :environment do
    [User, Person, Project, Institution, Investigation, Study, Assay,
     DataFile, Model, Sop, Publication, ContentBlob].each do |c|
      count = 0
      c.all.each do |res|
        if res.attributes["uuid"].nil?
          class << res
            def record_timestamps
              false
            end
          end
          if !res.valid?
            puts "Validation error with #{res.class.name}:#{res.id}"
            puts res.errors.full_messages.join(", ")
          else
            res.save!
          end
          count += 1
        end
      end
      puts "#{count} UUIDs generated for #{c.name}" unless count < 1
    end
  end

  desc "Lists all publicly available assets"
  task :list_public_assets => :environment do
    [Investigation, Study, Assay, DataFile, Model, Sop, Publication].each do |assets|
    #  :logout
      assets.all.each do |asset|
        if asset.can_view?
          puts "#{asset.title} - #{asset.id}"
        end
      end
    end
  end

  private

  #returns true if the tag is over 30 chars long, or contains colons, semicolons, comma's or forward slash
  def dubious_tag?(tag)
    tag.length>30 || [";", ",", ":", "/"].detect { |c| tag.include?(c) }
  end

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    def Fixtures.identify(label)
      label.to_s.hash.abs
    end
  end

  def create_tag name, context, taggable_type
    tag=ActsAsTaggableOn::Tag.find :first, :conditions=>{:name=>name}
    if tag.nil?
      tag=ActsAsTaggableOn::Tag.new(:name=>name)
      tag.save!
    end
    if tag.taggings.detect { |tagging| tagging.context==context && tagging.taggable_type==taggable_type }.nil?
      tagging=ActsAsTaggableOn::Tagging.new(:tag_id=>tag.id, :context=>context, :taggable_type=>taggable_type)
      tagging.save!
    end
  end

end
