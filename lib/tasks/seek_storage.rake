namespace :seek do
  namespace :storage do
    desc 'Copy local ContentBlob files (originals + derivatives) to the configured S3 backend'
    task copy_local_to_s3: :environment do
      require 'seek/storage/local_to_s3_migrator'

      dry_run = %w[1 true].include?(ENV['DRY_RUN'])

      if dry_run
        puts 'DRY-RUN mode — no files will be uploaded.'
      else
        puts 'Copying local files to S3...'
      end
      puts

      migrator = Seek::Storage::LocalToS3Migrator.new(dry_run: dry_run)
      result   = migrator.run

      puts
      puts result.summary
      abort "Migration finished with #{result.failed} failure(s)." if result.failed.positive?
    rescue Seek::Storage::ConfigurationError => e
      abort "Configuration error: #{e.message}"
    end

    desc 'Test connectivity to the configured storage backend'
    task test: :environment do
      adapter = Seek::Storage.adapter_for('dat')

      unless adapter.respond_to?(:test_connection)
        puts 'Storage backend: local — no connectivity test needed.'
        next
      end

      print 'Testing connection to S3 bucket... '
      result = adapter.test_connection

      if result[:success]
        puts 'OK'
        puts result[:message]
      else
        puts 'FAILED'
        warn result[:message]
        abort
      end
    rescue Seek::Storage::ConfigurationError => e
      abort "Configuration error: #{e.message}"
    end
  end
end
