#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'seek/mime_types'

include Seek::MimeTypes

namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks => [
           :environment,
           :fix_slideshare_content_type,
           :ensure_valid_content_blobs,
           :upgrade_content_blobs,
           :update_jws_online,
           :turn_off_biosamples
       ]

  #these are the tasks that are executes for each upgrade as standard, and rarely change
  task :standard_upgrade_tasks => [
           :environment,
           :clear_filestore_tmp,
           :repopulate_auth_lookup_tables,
           :resynchronise_ontology_types
       ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade => [:environment, "db:migrate", "db:sessions:clear", "tmp:clear"]) do

    solr=Seek::Config.solr_enabled
    Seek::Config.solr_enabled=false

    Rake::Task["seek:standard_upgrade_tasks"].invoke
    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr
    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:update_jws_online=>:environment) do
    Seek::Config.jws_online_root='https://jws2.sysmo-db.org'
  end

  task(:turn_off_biosamples=>:environment) do
    Seek::Config.biosamples_enabled=false
  end

  task(:clear_delayed_jobs=>:environment) do
    Delayed::Job.destroy_all
    #need to add a new authlookup job as these were added before being cleared as part of the standard_upgrade_tasks
    AuthLookupUpdateJob.new.queue_job(0,Time.now)
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

  desc "ensures all content blobs are valid"
  task(:ensure_valid_content_blobs => :environment) do
    puts "Validating all content blobs"
    content_blobs = ContentBlob.all
    total = 0
    updated = 0
    errors = []

    content_blobs.each_slice(10) do |batch|
      batch.each do |content_blob|
        fail = false

        if content_blob.valid?
          print "."
        else
          if content_blob.original_filename.blank? && content_blob.url.blank?
            content_blob.original_filename = 'unnamed_file'
            if (ext = mime_extensions(content_blob.content_type).first)
              content_blob.original_filename += ".#{ext}"
            end
            if content_blob.save
              updated += 1
              print 'C'
            else
              fail = true
            end
          else
            fail = true
          end
        end

        if fail
          print 'E'
          error = "Error saving content blob ID #{content_blob.id}:\n"
          error << content_blob.errors.full_messages.join("\n").inspect
          errors << error
        end

        total += 1
      end
      puts " (#{total} / #{content_blobs.count})"
    end

    unless errors.empty?
      puts "One or more errors occurred:"
      errors.each do |e|
        puts e
        puts
      end
    end

    puts
    puts "#{updated} content blobs renamed."
    puts "Done."
  end

  desc 'updates content types for slideshare urls, which sometimes incorrectly stored as application/xml'
  task(:fix_slideshare_content_type => :environment) do
    ContentBlob.where('url IS NOT NULL').each do |cb|
      handler = Seek::DownloadHandling::HTTPHandler.new(cb.url)
      if handler.send(:is_slideshare_url?)
        cb.update_attribute(:content_type,'text/html')
        cb.update_attribute(:is_webpage,true)
      end
    end
  end

  desc "calculate sizes and fetch remote content blobs"
  task(:upgrade_content_blobs => :environment) do
    puts "Calculating content blob sizes"
    content_blobs = ContentBlob.all
    job_count = Delayed::Job.where('handler LIKE ?', '%RemoteContentFetchingJob%').count
    total = 0
    errors = []

    content_blobs.each_slice(10) do |batch|
      batch.each do |content_blob|
        if content_blob.save
          print "."
          content_blob.send(:create_retrieval_job)
        else
          print 'E'
          error = "Error saving content blob ID #{content_blob.id}:\n"
          error << content_blob.errors.full_messages.join("\n").inspect
          errors << error
        end
        total += 1
      end
      puts " (#{total} / #{content_blobs.count})"
    end

    unless errors.empty?
      puts "One or more errors occurred:"
      errors.each do |e|
        puts e
        puts
      end
    end

    puts
    jobs_created = Delayed::Job.where('handler LIKE ?', '%RemoteContentFetchingJob%').count - job_count
    puts "#{jobs_created} download jobs queued."
    puts "Done."
  end

  private

  def read_label_map type
    file = "#{type.to_s}_label_mappings.yml"
    file = File.join(Rails.root, "config", "default_data", file)
    YAML::load_file(file)
  end

  def normalize_name(name, remove_special_character=true, replace_umlaut=false)
    #handle the characters that can't be handled through normalization
    %w[ØO].each do |s|
      name.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
    end

    codepoints = name.mb_chars.normalize(:d).split(//u)
    if remove_special_character
      ascii=codepoints.map(&:to_s).reject { |e| e.bytesize > 1 }.join
    end
    if replace_umlaut
      ascii=codepoints.map(&:to_s).collect { |e| e == '̈' ? 'e' : e }.join
    end
    ascii
  end
end
