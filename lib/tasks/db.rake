require 'rubygems'
require 'rake'
require 'terrapin'

# This extends teh regular task, to tweak the schema.rb file and remove mysql specific elements. Since Rails 5 schema.rb is no
# longer db agnostic - see https://github.com/rails/rails/issues/26209
Rake::Task['db:schema:dump'].enhance do
  begin
    cmd = Terrapin::CommandLine.new("sed -e 's/charset: \"[^\"]*\", //' -e 's/collation: \"[^\"]*\", //' db/schema.rb > db/schema2.rb " \
      '&& mv db/schema2.rb db/schema.rb')
    cmd.run
  rescue StandardError => e
    puts "Failed to convert schema.rb to db agnostic - #{e.message}"
  end
end

namespace :db do
  namespace :sessions do
    desc 'Trims sessions in batches according to env vars \'BATCH_SIZE\' and \'DAYS_OLD\' (Defaults => BATCH_SIZE: 1000, DAYS_OLD: 7).'
    task(batch_trim: :environment) do
      batch_size = ENV['BATCH_SIZE']&.to_i || 1_000
      days_old = ENV['DAYS_OLD']&.to_i || 7
      cutoff_date = days_old.days.ago

      deleted_total = 0
      loop do
        delete_ids = ActiveRecord::SessionStore::Session.where('updated_at < ?',
                                                               cutoff_date).limit(batch_size).pluck(:id)
        deleted_count = delete_ids.count
        ActiveRecord::SessionStore::Session.where(id: delete_ids).delete_all
        deleted_total += deleted_count

        puts "Deleted #{deleted_count} sessions (Total: #{deleted_total})"
        break if delete_ids.empty?

        sleep(1) # Wait longer between batches to release locks
      end

      puts "\nFinished! Deleted #{deleted_total} total sessions older than #{days_old} days."
    end
  end
end