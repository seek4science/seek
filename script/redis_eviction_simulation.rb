#!/usr/bin/env ruby

# Redis eviction simulation for the shared cache + sessions instance (issue #2655).
#
# SEEK runs Rails.cache and user sessions on ONE Redis instance with `maxmemory-policy allkeys-lru`.
# maxmemory is instance-wide, so under memory pressure Redis is free to evict session keys, not just
# cache entries - a silent forced logout before the 30-minute session expiry. This script verifies
# that risk for real instead of trusting the LRU docs: it stands up a throwaway Redis with a tiny
# maxmemory, creates real session-style keys (each with a 30-minute TTL, exactly like
# config/initializers/session_store.rb), then floods the cache namespace and reports what survived.
#
# It distinguishes "active" sessions (GET-touched during the flood, as a logged-in user's requests
# would) from "idle" ones (never touched), to show how much the LRU recency of active sessions
# actually protects them.
#
# Run with the SEEK bundle so the redis gem is available, and with Docker running:
#
#   bundle exec ruby script/redis_eviction_simulation.rb
#
# Tunables (env): SIM_MAXMEMORY (8mb), SIM_SESSIONS (50), SIM_VALUE_BYTES (3000),
# SIM_CACHE_WRITES (20000). Uses a throwaway container on port 6380; nothing else is touched.

require 'redis'

CONTAINER    = 'seek-redis-eviction-test'
PORT         = 6380
MAXMEMORY    = ENV.fetch('SIM_MAXMEMORY', '8mb')
SESSIONS     = Integer(ENV.fetch('SIM_SESSIONS', '50'))
VALUE_BYTES  = Integer(ENV.fetch('SIM_VALUE_BYTES', '3000'))
CACHE_WRITES = Integer(ENV.fetch('SIM_CACHE_WRITES', '20000'))
SESSION_TTL  = 30 * 60
TOUCH_EVERY  = 2000 # touch active sessions after roughly this many cache writes

def start_throwaway_redis
  system("docker rm -f #{CONTAINER} > /dev/null 2>&1")
  ok = system("docker run -d --name #{CONTAINER} -p #{PORT}:6379 redis:8.6-alpine " \
              "redis-server --maxmemory #{MAXMEMORY} --maxmemory-policy allkeys-lru > /dev/null")
  abort 'could not start the throwaway Redis container (is Docker running?)' unless ok

  60.times do
    return if system("docker exec #{CONTAINER} redis-cli ping 2>/dev/null | grep -q PONG")

    sleep 0.5
  end
  abort 'the throwaway Redis did not become ready'
end

def stop_throwaway_redis
  system("docker rm -f #{CONTAINER} > /dev/null 2>&1")
end

start_throwaway_redis
at_exit { stop_throwaway_redis }

redis = Redis.new(host: '127.0.0.1', port: PORT)
value = 'x' * VALUE_BYTES

# Session keys with a real 30-minute EXPIRE, like the redis-store session store sets.
SESSIONS.times do |i|
  redis.set("session:active:#{i}", value, ex: SESSION_TTL)
  redis.set("session:idle:#{i}", value, ex: SESSION_TTL)
end
puts "created #{SESSIONS} active + #{SESSIONS} idle session keys " \
     "(#{VALUE_BYTES} B each, #{SESSION_TTL / 60} min TTL), maxmemory=#{MAXMEMORY}"

# Flood the cache namespace, touching the active sessions periodically.
writes = 0
while writes < CACHE_WRITES
  redis.pipelined do |pipe|
    100.times do
      pipe.set("cache:blob:#{writes}", value)
      writes += 1
    end
  end
  next unless (writes % TOUCH_EVERY).zero?

  SESSIONS.times { |i| redis.get("session:active:#{i}") }
end

stats        = redis.info
evicted      = stats['evicted_keys'].to_i
active_alive = redis.keys('session:active:*').size
idle_alive   = redis.keys('session:idle:*').size
cache_alive  = redis.keys('cache:blob:*').size

puts
puts "cache writes attempted:    #{writes}"
puts "used_memory:               #{stats['used_memory_human']} (maxmemory #{MAXMEMORY})"
puts "evicted_keys:              #{evicted}"
puts "surviving active sessions: #{active_alive}/#{SESSIONS}"
puts "surviving idle sessions:   #{idle_alive}/#{SESSIONS}"
puts "surviving cache keys:      #{cache_alive}"
puts

if evicted.zero?
  puts 'No eviction occurred - raise SIM_CACHE_WRITES or lower SIM_MAXMEMORY and retry.'
elsif active_alive == SESSIONS && idle_alive == SESSIONS
  puts 'CONCLUSION: under this load only cache keys were evicted; all sessions survived.'
else
  puts 'CONCLUSION: sessions WERE evicted under sustained cache pressure - the shared-instance risk is real.'
  puts "  active lost: #{SESSIONS - active_alive}, idle lost: #{SESSIONS - idle_alive} " \
       '(touching active sessions helps under LRU but is not a guarantee).'
  puts '  Mitigation: raise SEEK_REDIS_MAXMEMORY; if pressure persists, split cache and sessions ' \
       'onto separate Redis instances.'
end
