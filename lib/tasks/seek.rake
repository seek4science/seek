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
    Seek::Util.searchable_types.each do |type|
      ReindexingQueue.enqueue(type.all)
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

end
