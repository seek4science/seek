# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'time'
require 'active_record/fixtures'
require 'csv'

namespace :seek do
  desc 'Creates background jobs to rebuild all authorization lookup table for all items.'
  task(repopulate_auth_lookup_tables: :environment) do
    puts "..... repopulating auth lookup tables ..."
    Seek::Util.authorized_types.each do |type|
      type.remove_invalid_auth_lookup_entries
      type.find_each do |item|
        AuthLookupUpdateQueue.enqueue(item)
      end
    end
  end

  desc 'Rebuild all authorization lookup table for all items.'
  task(repopulate_auth_lookup_tables_sync: :environment) do
    item_count = 0
    start_time = Time.now
    puts "Users: #{User.count}"
    Seek::Util.authorized_types.each do |type|
      puts "#{type.name} (#{type.count}):"
      ActiveRecord::Base.connection.execute("delete from #{type.lookup_table_name}")
      type.find_each do |item|
        item.update_lookup_table_for_all_users
        print '.'
        item_count += 1
      end
      puts
    end
    seconds = Time.now - start_time
    items_per_second = item_count.to_f / seconds.to_f
    puts "Done - #{seconds}s elapsed (#{items_per_second} items per second)"
  end


  desc 'Rebuilds all authorization tables for a given user - you are prompted for a user id'
  task(repopulate_auth_lookup_for_user: :environment) do
    puts 'Please provide the user id:'
    user_id = STDIN.gets.chomp
    user = user_id == '0' ? nil : User.find(user_id)
    Seek::Util.authorized_types.each do |type|
      table_name = type.lookup_table_name
      ActiveRecord::Base.connection.execute("delete from #{table_name} where user_id = #{user_id}")
      assets = type.includes(:policy)
      c = 0
      total = assets.count
      ActiveRecord::Base.transaction do
        assets.each do |asset|
          asset.update_lookup_table user
          c += 1
          puts "#{c} done out of #{total} for #{type.name}" if c % 10 == 0
        end
      end
      count = ActiveRecord::Base.connection.select_one("select count(*) from #{table_name} where user_id = #{user_id}").values[0]
      puts "inserted #{count} records for #{type.name}"
      GC.start
    end
  end

  desc 'Creates background jobs to reindex all searchable things'
  task(reindex_all: :environment) do
    Seek::Util.searchable_types.collect(&:to_s).each do |type|
      ReindexAllJob.perform_later(type)
    end
  end

  desc('clears temporary files from filestore/tmp')
  task(clear_filestore_tmp: :environment) do
    puts "..... clearing the filestore tmp directory ..."
    FileUtils.rm_r(Dir["#{Seek::Config.temporary_filestore_path}/*"])
  end

  desc('clears converted formats for assets, such as pdf and text for browser viewing and search indexing respectively. If cleared these will be regenerated when needed')
  task(clear_converted_assets: :environment) do
    FileUtils.rm_r(Dir["#{Seek::Config.converted_filestore_path}/*"])
  end

  desc('Synchronised the assay and technology types assigned to assays according to the current ontology, resolving any suggested types that have been added')
  task(resynchronise_ontology_types: [:environment, 'tmp:create']) do
    synchronizer = Seek::Ontologies::Synchronize.new
    synchronizer.synchronize
  end

  desc "clear rack attack's throttling cache"
  task clear_rack_attack_cache: :environment do
    Rack::Attack.cache.store.delete_matched("#{Rack::Attack.cache.prefix}:*")
    puts 'Done'
  end

  desc "populate the postions of assays"
  task populate_positions: :environment do
    Study.all.each do |s|
      position = 1
      s.assays.each do |a|
        a.position = position
        position += 1
        disable_authorization_checks do
          puts a.save
        end
      end
    end
  end

  desc "Clear encrypted settings"
  task clear_encrypted_settings: :environment do
    Settings.where(var: Seek::Config.encrypted_settings).destroy_all
    puts 'Encrypted settings cleared'
  end

  desc "Convert workflows to use git backend"
  task convert_workflows_to_git: :environment do
    puts 'Converting Workflows to git: '
    count = 0
    gv_count = Git::Version.count
    gr_count = Git::Repository.count
    Workflow.includes(:git_versions).find_each do |workflow|
      begin
        Git::Converter.new(workflow).convert(unzip: true)
      rescue StandardError => e
        print 'E'
        STDERR.puts "Error converting Workflow #{workflow.id}"
        STDERR.puts e.message
        e.backtrace.each { |l| STDERR.puts(l) }
      end
      count += 1
      print '.'
    end
    puts
    puts "Converted #{count} Workflows"
    puts "Created #{Git::Repository.count - gr_count} GitRepositories"
    puts "Created #{Git::Version.count - gv_count} GitVersions"
  end

  desc "Rebuild workflow internals"
  task rebuild_workflow_internals: :environment do
    puts 'Rebuilding workflow internals: '
    count = 0
    disable_authorization_checks do
      Workflow.includes(:git_versions, :versions).find_each do |workflow|
        ([workflow] + workflow.standard_versions.to_a + workflow.git_versions.to_a).each do |wf|
          begin
            wf.refresh_internals
            if wf.save(touch: false)
              print '.'
              count += 1
            else
              print 'E'
            end
          rescue StandardError => e
            puts "Error for #{wf.class} #{wf.id}: #{e.class.name} (#{e.message})#{e.backtrace.join("\n")}"
          end
        end
      end
    end
    puts
    puts "Refreshed #{count} Workflows/versions"
  end

  desc 'Create API examples'#
  task create_api_examples: :environment do
    puts "Writing API examples..."
    system("RAILS_ENV=test SEEK_WRITE_EXAMPLES=true rails test test/integration/api -n /test_write_.+_example/")
  end

  task(convert_mysql_charset: [:environment]) do
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'mysql2'
      puts "Attempting MySQL database conversion"
      # Get charset from database.yml, then find appropriate collation from mysql
      db = ActiveRecord::Base.connection.current_database
      charset = ActiveRecord::Base.connection.instance_values["config"][:encoding] || 'utf8mb4'
      collation = "#{charset}_unicode_ci" # Prefer e.g. utf8_unicode_ci over utf8_general_ci
      collation = ActiveRecord::Base.connection.execute("SHOW COLLATION WHERE Charset = '#{charset}' AND Collation = '#{collation}';").first&.first
      unless collation
        # Pick default collation for given charset if above collation not available
        collation = ActiveRecord::Base.connection.execute("SHOW COLLATION WHERE Charset = '#{charset}' `Default` = 'Yes';").first&.first
        unless collation
          puts "Could not find collation for charset: #{charset}, aborting"
          return
        end
      end

      puts "Converting database: #{db} to character set: #{charset}, collation: #{collation}"

      # Set database defaults
      puts "Setting default charset and collation"
      ActiveRecord::Base.connection.execute("ALTER DATABASE #{db} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation};")

      # Set/convert each table
      tables = ActiveRecord::Base.connection.exec_query("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA='#{db}' AND TABLE_COLLATION != '#{collation}';").rows.flatten
      puts "#{tables.count} tables to convert"
      tables.each do |table|
        puts "  Converting #{table}"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET #{charset} COLLATE #{collation};")
      end
      puts "Done"
    else
      puts "Database adapter is: #{ActiveRecord::Base.connection.instance_values["config"][:adapter]}, doing nothing"
    end
  end

end
