require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'

namespace :seek_dev do
  desc 'A simple task for quickly setting up a project and institution, and assigned the first user to it. This is useful for quickly setting up the database when testing. Need to create a default user before running this task'
  task(:initial_membership=>:environment) do
    p=Person.first
    raise Exception.new "Need to register a person first" if p.nil? || p.user.nil?

    User.with_current_user p.user do
      project=Project.new :title=>"Project X"
      institution=Institution.new :title=>"The Institute"
      project.save!
      institution.projects << project
      institution.save!
      p.update_attributes({"work_group_ids"=>["#{project.work_groups.first.id}"]})
    end
  end

  desc 'finds duplicate create activity records for the same item'
  task(:duplicate_activity_creates=>:environment) do
    duplicates = ActivityLog.duplicates("create")
    if duplicates.length>0
      puts "Found #{duplicates.length} duplicated entries:"
      duplicates.each do |duplicate|
        matches = ActivityLog.where({:activity_loggable_id=>duplicate.activity_loggable_id,:activity_loggable_type=>duplicate.activity_loggable_type,:action=>"create"},:order=>"created_at ASC")
        puts "ID:#{duplicate.id}\tLoggable ID:#{duplicate.activity_loggable_id}\tLoggable Type:#{duplicate.activity_loggable_type}\tCount:#{matches.count}\tCreated ats:#{matches.collect{|m| m.created_at}.join(", ")}"
      end
    else
      puts "No duplicates found"
    end
  end

  desc 'create 50 randomly named unlinked projects'
  task(:random_projects=>:environment) do
    (0...50).to_a.each do
      title=("A".."Z").to_a[rand(26)]+" #{UUIDTools::UUID.random_create.to_s}"
      p=Project.create :title=>title
      p.save!
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

  task(:refresh_content_types => :environment) do

    ContentBlob.all.each do |cb|
      filename = cb.original_filename
      unless filename.nil?
        file_format = filename.split('.').last.try(:strip)
        possible_mime_types = cb.mime_types_for_extension file_format
        type = possible_mime_types.sort.first || "application/octet-stream"
        type = type.gsub("image/jpg","image/jpeg") unless type.nil?

        cb.content_type = type
        cb.save
      end
    end

  end

  desc "display contributor types"
  task(:contributor_types=>:environment) do
    types = Seek::Util.user_creatable_types.collect do |type|
      type.all.collect do |thing|
        if thing.respond_to?(:contributor)
          if !thing.contributor.nil?
            "#{type.name} - #{thing.contributor.class.name}"
          end
        else
          pp "No contributor for #{type}"
          nil
        end
      end.flatten.compact.uniq
    end.flatten.uniq
    pp types
  end

  desc "display user contributors without people"
  task(:contributors_without_people=>:environment) do
    matches = Seek::Util.user_creatable_types.collect do |type|
      type.all.select do |thing|
        thing.respond_to?(:contributor_type) && thing.contributor.is_a?(User) && thing.contributor.person.nil?
      end
    end.flatten
    pp "#{matches.size} items found with a user contributor and no person"
    matches.each do |match|
      pp "\t#{match.class.name} - #{match.id}"
    end

  end

  desc "Generate an XMI db/schema.xml file describing the current DB as seen by AR. Produces XMI 1.1 for UML 1.3 Rose Extended, viewable e.g. by StarUML"
  task :xmi => :environment do
    require 'uml_dumper.rb'
    File.open("doc/data_models/schema.xmi", "w") do |file|
      ActiveRecord::UmlDumper.dump(ActiveRecord::Base.connection, file)
    end
    puts "Done. Schema XMI created as doc/data_models/schema.xmi."
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

  desc "Dumps current compounds and synoymns to a yaml file for the seed process"
  task :dump_compounds_and_synonyms => :environment do
    format_class = "YamlDb::Helper"
    dir = 'compound_dump_tmp'
    puts "Dumping database"
    SerializationHelper::Base.new(format_class.constantize).dump_to_dir dump_dir("/#{dir}")
    puts "Copying compound and synonym files"
    FileUtils.copy("db/#{dir}/compounds.yml", 'config/default_data/')
    FileUtils.copy("db/#{dir}/synonyms.yml", 'config/default_data/')
    puts "Cleaning up"
    FileUtils.rm_r("db/#{dir}/")
  end


  task :analyse_assays_and_their_types => :environment do
    assay_type_uri_hash = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri
    assay_type_uri_hash = assay_type_uri_hash.merge(Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri)

    assay_type_label_hash = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label
    assay_type_label_hash = assay_type_label_hash.merge(Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_label)

    technology_type_uri_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri
    technology_type_label_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label

    assay_type_label_known_mapping = ["generic experimental assay","generic modelling analysis","modelling analysis type"]
    technology_type_label_known_mapping = ["technology","enzymatic activity experiments"]

    Assay.all.each do |assay|
      id = assay.id
      assay_type_label = assay.assay_type_label
      assay_type_uri = assay.assay_type_uri
      technology_type_uri = assay.technology_type_uri
      technology_type_label = assay.technology_type_label

      technology_type_label = technology_type_label.downcase.gsub("_"," ") unless technology_type_label.nil?
      assay_type_label = assay_type_label.downcase.gsub("_"," ") unless assay_type_label.nil?

      if assay_type_label.blank? && assay_type_uri.blank?
        puts "No assay type uri or label defined, will be reset to the root class - #{id}".green
      elsif assay_type_uri.blank? || assay_type_uri_hash[assay_type_uri].nil?
        if assay_type_label_known_mapping.include?(assay_type_label)
          puts "Invalid assay type uri and but the label is recognised as a known mapping to fix '#{assay_type_label}' - #{id}".green
        elsif assay_type_label_hash[assay_type_label].nil?
          if technology_type_label_hash[assay_type_label].nil?
            if technology_type_uri_hash[assay_type_uri].nil?
              puts "Invalid assay type uri and it cannot be resolved by the label '#{assay_type_label}' - #{id}".red
              puts "\t uri is #{assay_type_uri}".red
            else
              puts "Invalid assay type uri and it cannot be resolved by the label '#{assay_type_label}', but does match a technology type uri  - #{id}".orange
              puts "\t the assay type uri is #{assay_type_uri}"
              puts "\t this assays technology type label is currently #{technology_type_label}".orange
            end

          else
            puts "Invalid assay type uri and it cannot be resolved by the label, but does match a technology type '#{assay_type_label}' - #{id}".orange
            puts "\t this assays technology type label is currently #{technology_type_label}".orange
          end
        else
          puts "Invalid assay type uri but it can be resolved by the label '#{assay_type_label}' - #{id}".green
        end
      end

      unless assay.is_modelling?
        if technology_type_label.blank? && technology_type_uri.blank?
          puts "No technology type uri or label defined, will be reset to the root class - #{id}".green

        elsif technology_type_uri.blank? || technology_type_uri_hash[technology_type_uri].nil?
          if technology_type_label_known_mapping.include?(technology_type_label)
            puts "Invalid technology type uri and but the label is recognised as a known mapping to fix '#{technology_type_label}' - #{id}".green
          elsif technology_type_label_hash[technology_type_label].nil?
            if assay_type_label_hash[technology_type_label].nil?
              if assay_type_uri_hash[technology_type_uri].nil?
                puts "Invalid technology type uri and it cannot be resolved by the label '#{technology_type_label}' - #{id}".red
                puts "\t uri is #{technology_type_uri}".red
              else
                puts "Invalid technology type uri and it cannot be resolved by the label '#{technology_type_label}', but does match a assay type uri  - #{id}".orange
                puts "\t the technology type uri is #{technology_type_uri}"
                puts "\t this assays assay type label is currently #{assay_type_label}".orange
              end

            else
              puts "Invalid technology type uri and it cannot be resolved by the label, but does match an assay type '#{technology_type_label}' - #{id}".orange
              puts "\t this assays assay type label is currently #{assay_type_label}".orange
            end
          else
            puts "Invalid technology type uri but it can be resolved by the label '#{technology_type_label}' - #{id}".green
          end
        end
      end


    end
  end


end