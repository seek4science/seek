require 'rubygems'
require 'rake'
require 'seek/factor_studied'
require 'libxml'
require 'simple-spreadsheet-extractor'
require 'active_record/fixtures'

namespace :db do
  desc 'seeds the database using seek:seed in conjuction with running the seed data defined in db/seeds.rb'
  task :seed=>[:environment,"seek:seed"]
end

namespace :seek do
  include Seek::FactorStudied
  include SysMODB::SpreadsheetExtractor

  desc 'seeds the database with the controlled vocabularies'
  task :seed=>[:environment,:seed_testing,:load_help_docs]

  desc 'seeds the database without the loading of help document, which is currently not working for SQLITE3 (SYSMO-678).'
  task :seed_testing=>[:environment,:create_controlled_vocabs,:tags,:compounds]

  desc 'creates the standard initial controlled vocublaries'
  task :create_controlled_vocabs=>[:environment,:culture_growth_types, :model_types, :model_formats, :disciplines, :organisms, :recommended_model_environments, :measured_items, :units, :project_roles, :assay_classes, :relationship_types]

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
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "compounds")
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "synonyms")
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "mappings")
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "mapping_links")
  end

  task(:culture_growth_types=>:environment) do
    CultureGrowthType.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "culture_growth_types")
  end

  task(:relationship_types=>:environment) do
    RelationshipType.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "relationship_types")
  end

  task(:model_types=>:environment) do
    ModelType.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "model_types")
  end

  task(:model_formats=>:environment) do
    ModelFormat.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "model_formats")
  end

  task(:disciplines=>:environment) do
    Discipline.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "disciplines")
  end

  task(:organisms=>:environment) do
    Organism.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "organisms")

    BioportalConcept.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "bioportal_concepts")

    Strain.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "strains")
    disable_authorization_checks do
      #create policy for strains
      Strain.all.each do |strain|
        if strain.policy.nil?
          policy = Policy.public_policy
          policy.save
          strain.policy_id = policy.id
          strain.update_column(:policy_id,policy.id)
        end
      end
    end

  end

  task(:recommended_model_environments=>:environment) do
    RecommendedModelEnvironment.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "recommended_model_environments")
  end

  task(:measured_items=>:environment) do
    MeasuredItem.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "measured_items")
  end

  task(:units=>:environment) do
    Unit.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "units")
  end

  task(:project_roles=>:environment) do
    ProjectRole.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "project_roles")
  end

  task(:assay_classes=>:environment) do
    AssayClass.delete_all
    ActiveRecord::Fixtures.create_fixtures(File.join(Rails.root, "config/default_data"), "assay_classes")
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

  def create_tag text, attribute
    text_value = TextValue.find_or_create_by_text(text)
    unless text_value.has_attribute_name?(attribute)
      seed = AnnotationValueSeed.create :value=>text_value, :attribute=>AnnotationAttribute.find_or_create_by_name(attribute)
    end
  end
end


