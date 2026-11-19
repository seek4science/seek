# Sweeps the filesystem side of Rails.cache (the RedisWithFileOverflowStore overflow path) for
# expired entries. Redis needs no equivalent sweep - it expires keys natively - but this is also
# a convenient, already-scheduled place to log Redis memory stats for ops visibility: evicted_keys
# rising is the signal that the shared Redis instance is under enough memory pressure that session
# keys could, in principle, start being evicted too.
class CacheOverflowCleanupJob < ApplicationJob
  def perform
    Rails.cache.cleanup
    log_redis_memory_stats
  end

  private

  def log_redis_memory_stats
    return unless Rails.cache.respond_to?(:redis_memory_stats)

    Rails.logger.info("[CacheOverflowCleanupJob] Redis memory stats: #{Rails.cache.redis_memory_stats}")
  rescue StandardError => e
    Rails.logger.warn("[CacheOverflowCleanupJob] Could not fetch Redis memory stats: #{e.message}")
  end
end
