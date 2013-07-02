require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :repopulate_auth_lookup_tables,
            :move_asset_files,
            :remove_converted_pdf_and_txt_files_from_asset_store,
            :clear_send_email_jobs
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

  task(:move_asset_files=>:environment) do
    oldpath=File.join(Rails.root,"filestore","content_blobs",Rails.env.downcase)
    newpath = Seek::Config.asset_filestore_path
    puts "Moving asset files from:\n\t#{oldpath}\nto:\n\t#{newpath}"
    FileUtils.mkdir_p newpath
    if File.exists? oldpath
      FileUtils.mv Dir.glob("#{oldpath}/*"),newpath
      puts "You can now safely remove #{oldpath}"
    else
      puts "The old asset location #{oldpath} doesn't exist, nothing to do"
    end
  end

  task(:remove_converted_pdf_and_txt_files_from_asset_store=>:environment) do
    FileUtils.rm Dir.glob(File.join(Seek::Config.asset_filestore_path,"*.pdf"))
    FileUtils.rm Dir.glob(File.join(Seek::Config.asset_filestore_path,"*.txt"))
  end

  task(:clear_send_email_jobs=>:environment) do
    Delayed::Job.where(["handler like ?","%SendPeriodicEmailsJob%"]).destroy_all
  end


end
