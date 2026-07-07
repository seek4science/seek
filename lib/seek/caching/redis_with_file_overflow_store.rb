module Seek
  module Caching
    # A cache store that writes small entries to a RedisCacheStore and overflows entries larger
    # than +max_redis_item_size+ to a FileStore instead. Delegates key normalization (namespacing,
    # path translation) to whichever backend store is targeted, so each backend's on-disk/on-wire
    # key format is identical to using that store directly - existing FileStore cache files remain
    # readable, and the Redis backend's own namespace option (if any) is honoured.
    class RedisWithFileOverflowStore < ActiveSupport::Cache::Store
      def initialize(redis_store:, file_store:, max_redis_item_size:, **options)
        super(options)
        @redis_store = redis_store
        @file_store = file_store
        @max_redis_item_size = max_redis_item_size
      end

      # RedisCacheStore#delete_matched only accepts Redis glob Strings and raises on anything
      # else, but SEEK has call sites that pass a Regexp (matching FileStore's looser, existing
      # behaviour). Scan Redis by hand and apply the matcher the same way FileStore does
      # (String#match, which accepts either a String or a Regexp) so both call site styles keep
      # working unmodified against either backend.
      def delete_matched(matcher, options = nil)
        redis_result = delete_matched_in_redis(matcher, options)
        file_result = @file_store.delete_matched(matcher, options)
        redis_result || file_result
      end

      private

      def read_entry(key, **options)
        redis_key = @redis_store.send(:normalize_key, key, options)
        entry = @redis_store.send(:read_entry, redis_key, **options)
        return entry if entry

        file_key = @file_store.send(:normalize_key, key, options)
        @file_store.send(:read_entry, file_key, **options)
      end

      def write_entry(key, entry, **options)
        payload = serialize_entry(entry, **options)

        if payload.bytesize <= @max_redis_item_size
          write_to_redis(key, entry, **options)
        else
          log_overflow(key, payload.bytesize)
          write_to_file(key, entry, **options)
        end
      end

      def write_to_redis(key, entry, **options)
        @file_store.send(:delete_entry, @file_store.send(:normalize_key, key, options), **options)
        @redis_store.send(:write_entry, @redis_store.send(:normalize_key, key, options), entry, **options)
      end

      def write_to_file(key, entry, **options)
        @redis_store.send(:delete_entry, @redis_store.send(:normalize_key, key, options), **options)
        @file_store.send(:write_entry, @file_store.send(:normalize_key, key, options), entry, **options)
      end

      def delete_entry(key, **options)
        redis_key = @redis_store.send(:normalize_key, key, options)
        file_key = @file_store.send(:normalize_key, key, options)
        redis_deleted = @redis_store.send(:delete_entry, redis_key, **options)
        file_deleted = @file_store.send(:delete_entry, file_key, **options)
        redis_deleted || file_deleted
      end

      def log_overflow(key, size)
        Rails.logger.info(
          '[Seek::Caching::RedisWithFileOverflowStore] overflow to disk ' \
          "key=#{key} size=#{size} max=#{@max_redis_item_size}"
        )
      end

      def redis_namespace_prefix
        namespace = @redis_store.options[:namespace]
        "#{namespace}:" if namespace
      end

      def matching_redis_keys(connection, cursor, scan_pattern, prefix, matcher)
        cursor, keys = connection.scan(cursor, match: scan_pattern, count: 1000)
        matching = keys.select do |k|
          bare_key = prefix ? k.delete_prefix(prefix) : k
          bare_key.match?(matcher)
        end
        [cursor, matching]
      end

      def scan_and_unlink(connection, scan_pattern, prefix, matcher)
        deleted = false
        cursor = '0'
        loop do
          cursor, matching = matching_redis_keys(connection, cursor, scan_pattern, prefix, matcher)
          unless matching.empty?
            connection.unlink(*matching)
            deleted = true
          end
          break if cursor == '0'
        end
        deleted
      end

      def delete_matched_in_redis(matcher, _options)
        prefix = redis_namespace_prefix
        scan_pattern = prefix ? "#{prefix}*" : '*'

        @redis_store.redis.then { |c| scan_and_unlink(c, scan_pattern, prefix, matcher) }
      end
    end
  end
end
