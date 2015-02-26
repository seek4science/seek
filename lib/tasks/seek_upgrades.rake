#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'

namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks => [
      :convert_image_to_png
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade => [:environment, "db:migrate", "db:sessions:clear", "tmp:clear"]) do

    solr=Seek::Config.solr_enabled
    Seek::Config.solr_enabled=false

    rerunable_tasks = %w(seek:clear_filestore_tmp
                         seek:repopulate_auth_lookup_tables
                         seek:resynchronise_ontology_types)
    rerunable_tasks.each do |task|
      Rake::Task[task].invoke
    end

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr
    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end



  desc "convert the avatar and model image from jpg to png"
  task(:convert_image_to_png => :environment) do
    avatar_filestore_path = Seek::Config.avatar_filestore_path
    Avatar.all.each do |avatar|
      filepath = avatar_filestore_path + "/#{avatar.id}.jpg"
      convert_path = avatar_filestore_path + "/#{avatar.id}.png"
      if File.exist?(filepath)
        puts "converting avatar #{avatar.id}"
        command = "convert #{filepath} #{convert_path}"
        begin
          cl = Cocaine::CommandLine.new(command)
          cl.run
          FileUtils.remove_file(filepath)
        rescue Cocaine::CommandNotFoundError => e
          puts 'convert command not found!'
        rescue => e
          error = e.message
          puts "Problem with converting avatar #{avatar.id}: " + error
        end
      else
        if File.exist?(convert_path)
          puts "avatar #{avatar.id} was already converted"
        else
          puts "no file exist at #{filepath}"
        end
      end
    end

    model_image_filestore_path = Seek::Config.model_image_filestore_path
    ModelImage.all.each do |model_image|
      filepath = model_image_filestore_path + "/#{model_image.id}.jpg"
      convert_path = model_image_filestore_path + "/#{model_image.id}.png"
      if File.exist?(filepath)
        puts "converting model image #{model_image.id}"
        convert_path = model_image_filestore_path + "/#{model_image.id}.png"
        command = "convert #{filepath} #{convert_path}"
        begin
          cl = Cocaine::CommandLine.new(command)
          cl.run
          FileUtils.remove_file(filepath)
        rescue Cocaine::CommandNotFoundError => e
          puts 'convert command not found!'
        rescue => e
          error = e.message
          puts "Problem with converting model image #{model_image.id}: " + error
        end
      else
        if File.exist?(convert_path)
          puts "model image  #{model_image.id} was already converted"
        else
          puts "no file exist at #{filepath}"
        end
      end
    end
  end
end
