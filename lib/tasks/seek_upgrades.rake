require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :repopulate_auth_lookup_tables,
            :copy_image_assets
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  desc("Copy image assets to the Seek::Config.resized_image_asset_filestore_path")
  task(:copy_image_assets=>:environment) do
    puts "Copying image asset files to:\n\t#{Seek::Config.resized_image_asset_filestore_path}"

    ContentBlob.all.each do |content_blob|
      if content_blob.is_image?
        content_blob.copy_image
      end
    end
  end
end
