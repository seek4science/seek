require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'lib/seek/factor_studied.rb'
require 'libxml'
require 'simple-spreadsheet-extractor'

namespace :db do
  desc 'seeds the database using seek:seed rather than db/seed.rb'
  task :seed=>[:environment,"seek:seed"]
end

namespace :seek do
  include Seek::FactorStudied
  include SysMODB::SpreadsheetExtractor

  
  desc 'seeds the database with the controlled vocabularies'
  task :seed=>[:environment,:seed_testing,:compounds,:load_help_docs]

  desc 'seeds the database without the loading of help document, which is currently not working for SQLITE3 (SYSMO-678). Also skips adding compounds from sabio-rk'
  task :seed_testing=>[:environment,:refresh_controlled_vocabs,:tags]

  desc 'refreshes, or creates, the standard initial controlled vocublaries'
  task :refresh_controlled_vocabs=>[:environment,:culture_growth_types, :model_types, :model_formats, :assay_types, :disciplines, :organisms, :technology_types, :recommended_model_environments, :measured_items, :units, :project_roles, :assay_classes, :relationship_types, :strains]

  desc "adds the default tags"
  task(:tags=>:environment) do

    File.open('config/default_data/expertise.list').each do |item|
      unless item.blank?
        item=item.chomp
        create_tag item, "expertise"
      end
    end

    File.open('config/default_data/tools.list').each do |item|
      unless item.blank?
        item=item.chomp
        create_tag item, "tool"
      end
    end
  end

    #update the old compounds and their annotations, add the new compounds and their annotations if they dont exist
  desc "adds or updates the compounds, synonyms and mappings using the Sabio-RK webservices"
  task(:compounds=>:environment) do
    compound_list = []
    File.open('config/default_data/compound.list').each do |compound|
      unless compound.blank?
        compound_list.push(compound.chomp) if !compound_list.include?(compound.chomp)
      end
    end

    count_new = 0
    count_update=0
    compound_list.each do |compound|
      compound_object = update_substance compound
      if compound_object.new_record?
        if compound_object.save
          count_new += 1
        else
          puts "the compound #{try_block { compound_object.name }} couldn't be created: #{compound_object.errors.full_messages}"
        end
      else
        if compound_object.save
          count_update += 1
        else
          puts "the compound #{try_block { compound_object.name }} couldn't be updated: #{compound_object.errors.full_messages}"
        end
      end
    end
    puts "#{count_new.to_s} compounds and synonyms were created"
    puts "#{count_update.to_s} compounds and synonyms were updated"
  end

  desc 're-extracts bioportal information about all organisms, overriding the cached details'
  task(:refresh_organism_concepts=>:environment) do
    Organism.all.each do |o|
      o.concept({:refresh=>true})
    end
  end

  task(:strains=>:environment) do
    revert_fixtures_identify
    Strain.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "strains")
    disable_authorization_checks do
      #create policy for strains
      Strain.all.each do |strain|
        if strain.policy.nil?
          strain.policy = Policy.public_policy
          strain.save!
        end
      end
    end
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

  task(:project_roles=>:environment) do
    revert_fixtures_identify
    ProjectRole.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "project_roles")
  end

  task(:assay_classes=>:environment) do
    revert_fixtures_identify
    AssayClass.delete_all
    Fixtures.create_fixtures(File.join(RAILS_ROOT, "config/default_data"), "assay_classes")
  end

  desc "Dumps help documents and attachments/images"
  task :dump_help_docs => :environment do
    format_class = "YamlDb::Helper"
    dir = 'help_dump_tmp'
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
      dir = '../config/default_data/help/'
      SerializationHelper::Base.new(format_class.constantize).load_from_dir dump_dir("/#{dir}")
        #Copy images
      FileUtils.cp_r('config/default_data/help_images', 'public/')
        #Destroy irrelevent db_files
      (DbFile.all - HelpAttachment.all.collect { |h| h.db_file }).each { |d| d.destroy }
    else
      puts "Aborted - Couldn't find any help documents in /config/default_data/help/"
    end
  end

  private

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    def Fixtures.identify(label)
      label.to_s.hash.abs
    end
  end

  def create_tag text, attribute
    text_value = TextValue.find_or_create_by_text(text)
    unless text_value.has_attribute_name?(attribute)
      seed = AnnotationValueSeed.create :value=>text_value, :attribute=>AnnotationAttribute.find_or_create_by_name(attribute)
    end
  end
end
