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
    desc 'Trims sessions in batches according to env vars \'SESSION_TRIM_BATCH_SIZE\' and \'SESSION_DAYS_TRIM_THRESHOLD\'. Defaults: SESSION_TRIM_BATCH_SIZE=1000, SESSION_DAYS_TRIM_THRESHOLD=30).'
    task(batch_trim: :environment) do
      batch_size = ENV.fetch('SESSION_TRIM_BATCH_SIZE', '1000').to_i
      days_old = ENV.fetch('SESSION_DAYS_TRIM_THRESHOLD', '30').to_i

      if batch_size <= 0
        abort "SESSION_TRIM_BATCH_SIZE must be a positive integer"
      end

      if days_old <= 0
        abort "SESSION_DAYS_TRIM_THRESHOLD must be a positive integer"
      end

      cutoff_date = days_old.days.ago
      deleted_total = 0


      puts "Deleting sessions older than #{days_old} days in batches of #{batch_size}..."
      puts "Cutoff: #{cutoff_date}"

      loop do
        delete_ids = ActiveRecord::SessionStore::Session
                       .where('updated_at < ?', cutoff_date)
                       .order(:updated_at, :id)
                       .limit(batch_size)
                       .pluck(:id)

        break if delete_ids.empty?

        deleted_count = ActiveRecord::SessionStore::Session
                          .where(id: delete_ids)
                          .delete_all

        deleted_total += deleted_count

        puts "Deleted #{deleted_count} sessions (Total: #{deleted_total})"

        sleep(1) # Wait longer between batches to release locks
      end

      puts "\nFinished! Deleted #{deleted_total} total sessions older than #{days_old} days."
    end
  end
end