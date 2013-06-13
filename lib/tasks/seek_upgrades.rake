require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :add_term_uris_to_assay_types,
            :add_term_uris_to_technology_types,
            :repopulate_auth_lookup_tables,
            :correct_content_type_for_jpg,
            :update_jws_online_root
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  desc "adds the term uri's to assay types"
  task :add_term_uris_to_assay_types=>:environment do
    #fix spelling error in earlier seed data
    type = AssayType.find_by_title("flux balanace analysis")
    unless type.nil?
      type.title = "flux balance analysis"
      type.save
    end

    yamlfile=File.join(Rails.root,"config","default_data","assay_types.yml")
    yaml=YAML.load_file(yamlfile)
    yaml.keys.each do |k|
      title = yaml[k]["title"]
      uri = yaml[k]["term_uri"]
      unless uri.nil?
        assay_type = AssayType.find(:first,:conditions=>["lower(title)=?",title.downcase])

        unless assay_type.nil?
              assay_type.term_uri = uri
              assay_type.save
        end
      else
        puts "No uri defined for assaytype #{title} so skipping adding term"
      end

    end
  end

  desc "adds the term uri's to technology types"
  task :add_term_uris_to_technology_types=>:environment do
    yamlfile=File.join(Rails.root,"config","default_data","technology_types.yml")
    yaml=YAML.load_file(yamlfile)
    yaml.keys.each do |k|
      title = yaml[k]["title"]
      uri = yaml[k]["term_uri"]
      unless uri.nil?
        tech_type = TechnologyType.find(:first,:conditions=>["lower(title)=?",title.downcase])
        unless tech_type.nil?
              tech_type.term_uri = uri
              tech_type.save
        end
      else
        puts "No uri defined for Technology Type #{title} so skipping adding term"
      end

    end
  end

  desc "content type of jpg is image/jpeg, instead of image/jpg"
  task(:correct_content_type_for_jpg=>:environment) do
    content_blobs = ContentBlob.find(:all, :conditions => ['content_type=?', 'image/jpg'])
    content_blobs.each do |cb|
      cb.content_type = 'image/jpeg'
      cb.save
    end
  end

  desc "update jws online root to point to http://jjj.mib.ac.uk/"
  task(:update_jws_online_root => :environment) do
    Seek::Config.jws_online_root = 'http://jjj.mib.ac.uk/'
  end




end
