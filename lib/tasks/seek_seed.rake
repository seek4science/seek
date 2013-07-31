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
  task :seed=>[:environment,:seed_testing,:load_help_docs]

  desc 'seeds the database without the loading of help document, which is currently not working for SQLITE3 (SYSMO-678).'
  task :seed_testing=>[:environment,:refresh_controlled_vocabs,:tags,:compounds]

  desc 'refreshes, or creates, the standard initial controlled vocublaries'
  task :refresh_controlled_vocabs=>[:environment,:culture_growth_types, :model_types, :model_formats, :assay_types, :disciplines, :organisms, :technology_types, :recommended_model_environments, :measured_items, :units, :project_roles, :assay_classes, :relationship_types]

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

  desc "seeds the database with the list of compounds and synonyms extracted from sabio-rk and stored in config/default_data/"
  task(:compounds=>:environment) do
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "compounds")
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "synonyms")
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "mappings")
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "mapping_links")
  end

  #update the old compounds and their annotations, add the new compounds and their annotations if they dont exist
  desc "updates the compounds, synonyms and mappings using the Sabio-RK webservices"
  task(:update_compounds=>:environment) do
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

  task(:culture_growth_types=>:environment) do
    revert_fixtures_identify
    CultureGrowthType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "culture_growth_types")
  end

  task(:relationship_types=>:environment) do
    revert_fixtures_identify
    RelationshipType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "relationship_types")
  end

  task(:model_types=>:environment) do
    revert_fixtures_identify
    ModelType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "model_types")
  end

  task(:model_formats=>:environment) do
    revert_fixtures_identify
    ModelFormat.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "model_formats")
  end

  task(:assay_types=>:environment) do
    revert_fixtures_identify
    AssayType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "assay_types")
  end

  task(:disciplines=>:environment) do
    revert_fixtures_identify
    Discipline.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "disciplines")
  end

  task(:organisms=>:environment) do
    revert_fixtures_identify
    Organism.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "organisms")

    BioportalConcept.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "bioportal_concepts")

    revert_fixtures_identify
    Strain.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "strains")
    disable_authorization_checks do
      #create policy for strains
      Strain.all.each do |strain|
        if strain.policy.nil?
          policy = Policy.public_policy
          policy.save
          strain.policy_id = policy.id
          strain.send(:update_without_callbacks)
        end
      end
    end

  end

  task(:technology_types=>:environment) do
    revert_fixtures_identify
    TechnologyType.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "technology_types")
  end

  task(:recommended_model_environments=>:environment) do
    revert_fixtures_identify
    RecommendedModelEnvironment.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "recommended_model_environments")
  end

  task(:measured_items=>:environment) do
    revert_fixtures_identify
    MeasuredItem.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "measured_items")
  end

  task(:units=>:environment) do
    revert_fixtures_identify
    Unit.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "units")
  end

  task(:project_roles=>:environment) do
    revert_fixtures_identify
    ProjectRole.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "project_roles")
  end

  task(:assay_classes=>:environment) do
    revert_fixtures_identify
    AssayClass.delete_all
    Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "assay_classes")
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

  desc "assign contributor to strains which dont have one"
  task :assign_contributor_to_strains => :environment do
    file_path = File.join(Rails.root, "config/default_data", "strains_with_contributor.yml")
    strains_from_yml = YAML::load(File.open(file_path)).values

    strains_without_contributor = Strain.all.select{|s| s.contributor.nil? }
    strains_from_yml.each do |strain_from_yml|
      strain = Strain.find_by_id(strain_from_yml['id'])
      if strains_without_contributor.include?(strain)
         contributor = User.find_by_id(strain_from_yml['contributor_id'])
         unless contributor.nil?
           strain.contributor = contributor
           disable_authorization_checks{strain.save}
         end
      end
    end
  end

  private

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    include ActiveRecord

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
