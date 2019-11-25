# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'time'
require 'active_record/fixtures'
require 'csv'

namespace :seek do
  desc 'Creates background jobs to rebuild all authorization lookup table for all items.'
  task(repopulate_auth_lookup_tables: :environment) do
    Seek::Util.authorized_types.each do |type|
      type.remove_invalid_auth_lookup_entries
      type.find_each do |item|
        AuthLookupUpdateQueue.create(item: item, priority: 1) # Duplicates will be caught by uniqueness check
      end
    end
    # 5 is an arbitrary number to take advantage of there being more than 1 worker dedicated to auth refresh
    5.times { AuthLookupUpdateJob.new.queue_job(1, 5.seconds.from_now) }
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
    Seek::Util.searchable_types.each do |type|
      ReindexingJob.new.add_items_to_queue type.all, 5.seconds.from_now, 2
    end
  end

  desc('clears temporary files from filestore/tmp')
  task(clear_filestore_tmp: :environment) do
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
end
