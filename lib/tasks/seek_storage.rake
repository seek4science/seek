namespace :seek do
  namespace :storage do
    desc 'Test connectivity to the configured storage backend'
    task test: :environment do
      adapter = Seek::Storage.adapter_for('dat')

      unless adapter.respond_to?(:test_connection)
        puts 'Storage backend: local — no connectivity test needed.'
        next
      end

      print "Testing connection to S3 bucket... "
      result = adapter.test_connection

      if result[:success]
        puts "OK"
        puts result[:message]
      else
        puts "FAILED"
        warn result[:message]
        abort
      end
    rescue Seek::Storage::ConfigurationError => e
      abort "Configuration error: #{e.message}"
    end
  end
end
