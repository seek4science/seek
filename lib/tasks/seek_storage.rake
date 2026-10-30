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

    desc 'Copy local Avatar/ModelImage master images (fleximage) to the configured S3 backend'
    task copy_fleximage_to_s3: :environment do
      require 'seek/storage/fleximage_to_s3_migrator'

      unless Seek::Storage.status[:backend].to_s == 's3'
        abort 'S3 backend is not configured. Set backend: s3 in seek_storage.yml.'
      end

      dry_run = %w[1 true].include?(ENV['DRY_RUN'])

      if dry_run
        puts 'DRY-RUN mode — no files will be uploaded.'
      else
        puts 'Copying local avatar/model-image files to S3...'
      end
      puts

      migrator = Seek::Storage::FleximageToS3Migrator.new(dry_run: dry_run)
      result   = migrator.run

      puts
      puts result.summary
      abort "Migration finished with #{result.failed} failure(s)." if result.failed.positive?
    rescue Seek::Storage::ConfigurationError => e
      abort "Configuration error: #{e.message}"
    end

    desc 'Delete abandoned direct-upload staging objects (DRY_RUN=1 lists only; MAX_AGE_HOURS overrides 24h)'
    task purge_stale_uploads: :environment do
      require 'seek/storage/stale_upload_cleaner'

      unless Seek::Storage.direct_upload_enabled?
        puts 'Storage backend: local — there is no staging area to clean.'
        next
      end

      dry_run = %w[1 true].include?(ENV['DRY_RUN'])
      max_age = if ENV['MAX_AGE_HOURS'].present?
                  ENV['MAX_AGE_HOURS'].to_f.hours
                else
                  Seek::Storage::StaleUploadCleaner::DEFAULT_MAX_AGE
                end

      puts 'DRY-RUN mode — nothing will be deleted.' if dry_run
      puts "Looking for staged uploads older than #{max_age.inspect}..."
      puts

      logger = Logger.new($stdout)
      logger.formatter = proc { |_severity, _time, _progname, msg| "#{msg}\n" }
      result = Seek::Storage::StaleUploadCleaner.new(max_age: max_age, dry_run: dry_run, logger: logger).run

      puts
      puts result.summary
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
