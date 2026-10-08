require_relative '../redis_config'

module Seek
  module Caching
    # A cache store that writes small entries to a RedisCacheStore and overflows entries larger
    # than +max_redis_item_size+ to a FileStore instead. Delegates key normalization (namespacing,
    # path translation) to whichever backend store is targeted, so each backend's on-disk/on-wire
    # key format is identical to using that store directly - existing FileStore cache files remain
    # readable, and the Redis backend's own namespace option (if any) is honoured.
    class RedisWithFileOverflowStore < ActiveSupport::Cache::Store
      # Builds the store the way config/environments/production.rb and development.rb do.
      # max_redis_item_size is a Proc so it re-reads Seek::Config.cache_max_redis_item_size on
      # every write rather than baking in a value captured once at boot - the setting is meant to
      # be tunable from the admin UI without a restart, and reading it eagerly here would
      # also mean touching the database while config/environments/*.rb is still being evaluated,
      # before Seek:: constants are even autoloadable (confirmed empirically - referencing Seek::
      # anything that early raises NameError).
      def self.build(file_cache_path)
        redis_store = ActiveSupport::Cache::RedisCacheStore.new(
          url: Seek::RedisConfig.url,
          namespace: 'cache'
        )
        file_store = ActiveSupport::Cache::FileStore.new(file_cache_path)
        new(redis_store: redis_store, file_store: file_store,
            max_redis_item_size: -> { Seek::Config.cache_max_redis_item_size })
      end

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

      # RedisCacheStore#clear flushes the whole Redis instance unless it's namespaced, in which
      # case it scopes itself to that namespace - relies on @redis_store being constructed with
      # a namespace (e.g. 'cache') when the instance is shared with sessions, or this would wipe
      # far more than the cache.
      def clear(options = nil)
        @redis_store.clear(options)
        @file_store.clear(options)
      end

      # Redis expires keys natively (RedisCacheStore#cleanup is itself a no-op that raises
      # NotImplementedError via the base class - "manual cleanup is not supported"), so only the
      # file side needs a sweep. Used by CacheOverflowCleanupJob.
      def cleanup(options = nil)
        @file_store.cleanup(options)
      end

      # Ops visibility for the shared-instance eviction tradeoff: used_memory shows
      # how full the instance is against maxmemory, and evicted_keys is the signal that Redis has
      # started discarding keys under maxmemory-policy - including, in principle, session keys.
      # expired_keys (natural TTL expiry - healthy) is included alongside so a reader can tell the
      # two apart, and keyspace_hits/misses give cache effectiveness. Surfaced daily by
      # CacheOverflowCleanupJob and on the admin dashboard (Status and statistics > Redis cache).
      REDIS_STAT_FIELDS = %w[used_memory used_memory_human maxmemory_human maxmemory_policy
                             evicted_keys expired_keys keyspace_hits keyspace_misses].freeze

      def redis_memory_stats
        @redis_store.redis.then { |c| c.info.slice(*REDIS_STAT_FIELDS) }
      end

      private

      def read_entry(key, **options)
        redis_key = @redis_store.send(:normalize_key, key, options)
        entry = @redis_store.send(:read_entry, redis_key, **options)
        return entry if entry

        file_key = @file_store.send(:normalize_key, key, options)
        @file_store.send(:read_entry, file_key, **options)
      end

      # Serialize the entry once, here, rather than letting the chosen backend re-serialize it. The
      # backends' own write_entry would call serialize_entry again, so an oversized value (the
      # overflow case - spreadsheet XML, notebook HTML) would otherwise be Marshalled and gzipped
      # twice per write. Serializing once also makes the routing decision exact: the byte size we
      # compare against the threshold is precisely the payload we store.
      #
      # This depends on an invariant: this store and both backends must share the same coder and
      # compression settings, so the payload produced here is read back correctly by whichever
      # backend's coder loads it. .build guarantees this - all three are constructed with defaults
      # (Marshal + Zlib, 1KB compress threshold) and .build exposes no way to customise a coder. If
      # a custom :coder/:compress is ever passed to one store but not the others, this reuse (and the
      # size comparison) would break; keep them in lockstep.
      def write_entry(key, entry, **options)
        payload = serialize_entry(entry, **options)

        if payload.bytesize <= max_redis_item_size
          write_to_redis(key, payload, **options)
        else
          log_overflow(key, payload.bytesize)
          write_to_file(key, payload, **options)
        end
      end

      def max_redis_item_size
        @max_redis_item_size.respond_to?(:call) ? @max_redis_item_size.call : @max_redis_item_size
      end

      # Deleting the entry from the non-chosen backend before writing to the chosen one is a
      # correctness invariant, not just tidiness. A key can legitimately move backends between
      # writes (e.g. a stable key whose value grows past, or shrinks below, the threshold). If the
      # old copy in the other backend were left in place, reads would usually still be correct
      # (read_entry checks Redis first), but only until the fresh copy disappears: Redis evicts
      # under maxmemory allkeys-lru, or either copy TTL-expires. A read that then falls through to
      # the surviving stale copy in the other backend would serve an out-of-date value. Removing it
      # here closes that window.
      #
      # The cost of the FileStore pre-delete (one File.exist? stat) is only paid on a cache *miss*,
      # since writes only happen when fetch misses - steady-state cache *hits* return from Redis in
      # read_entry without ever touching the filesystem.
      def write_to_redis(key, payload, **options)
        @file_store.send(:delete_entry, @file_store.send(:normalize_key, key, options), **options)
        @redis_store.send(:write_serialized_entry, @redis_store.send(:normalize_key, key, options), payload, **options)
      end

      def write_to_file(key, payload, **options)
        @redis_store.send(:delete_entry, @redis_store.send(:normalize_key, key, options), **options)
        @file_store.send(:write_serialized_entry, @file_store.send(:normalize_key, key, options), payload, **options)
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
          "key=#{key} size=#{size} max=#{max_redis_item_size}"
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
        scan_pattern = redis_scan_pattern(matcher, prefix)

        @redis_store.redis.then { |c| scan_and_unlink(c, scan_pattern, prefix, matcher) }
      end

      # Narrow the server-side SCAN so Redis filters most keys itself instead of shipping the whole
      # namespace to the client to be filtered in Ruby (matching_redis_keys still applies the exact
      # matcher afterwards, so this only shrinks the candidate set - it never decides the result).
      # The MATCH pattern must be a *superset* of what the matcher accepts: it can be looser, never
      # tighter, or we'd skip keys that should be deleted. We extract a literal substring that every
      # matching key is guaranteed to contain and let Redis pre-filter on "<prefix>*<literal>*"; if
      # none can be extracted we scan the whole namespace ("<prefix>*"), exactly as before.
      def redis_scan_pattern(matcher, prefix)
        base = prefix || ''
        literal = guaranteed_literal_substring(matcher)
        return "#{base}*" if literal.nil? || literal.empty?

        "#{base}*#{redis_glob_escape(literal)}*"
      end

      # Longest leading run of plain-literal characters guaranteed to appear in every string the
      # matcher accepts. Stops at the first regex-special character; if that character is a
      # quantifier (`*`, `?`, `{`) the preceding character is optional/variable and is dropped. A
      # String matcher is treated as a regex source, mirroring how String#match? (and FileStore's
      # delete_matched) interpret it. Returns nil when nothing literal can be guaranteed, which
      # falls back to a full-namespace scan.
      def guaranteed_literal_substring(matcher)
        source = matcher.is_a?(Regexp) ? matcher.source : matcher.to_s
        literal = source[%r{\A[A-Za-z0-9_\-/: ]+}]
        return nil if literal.nil?

        literal = literal[0..-2] if ['*', '?', '{'].include?(source[literal.length])
        literal
      end

      # Escape the Redis glob metacharacters so the extracted literal matches itself literally in
      # the SCAN MATCH pattern.
      def redis_glob_escape(str)
        str.gsub(/[\\*?\[\]]/) { |c| "\\#{c}" }
      end
    end
  end
end
