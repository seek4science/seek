# Migration from delayed_job to Sidekiq

This document outlines the migration from delayed_job to Sidekiq for background job processing in SEEK.

## What Changed

SEEK has migrated from using delayed_job with ActiveRecord backend to Sidekiq with Redis for background job processing. This provides:
- Better performance and scalability
- More efficient resource usage
- Modern, actively maintained job processing system

## Requirements

### New Dependency: Redis

Sidekiq requires Redis to be running. Redis is a fast in-memory data store used for job queuing.

**For Docker users:** The docker-compose.yml files have been updated to include a Redis service automatically.

**For local/manual installations:**
1. Install Redis:
   - Ubuntu/Debian: `sudo apt-get install redis-server`
   - macOS: `brew install redis`
   - Or download from: https://redis.io/download

2. Start Redis:
   - Ubuntu/Debian: `sudo systemctl start redis-server`
   - macOS: `brew services start redis`

3. Verify Redis is running: `redis-cli ping` (should respond with "PONG")

### Environment Variables

Set the `REDIS_URL` environment variable if Redis is not running on localhost:6379:
```bash
export REDIS_URL=redis://your-redis-host:6379/0
```

## Migration Steps

### 1. Update Dependencies
```bash
bundle install
```

### 2. Migrate Database (Optional)
The migration will drop the old `delayed_jobs` table which is no longer needed:
```bash
bundle exec rake db:migrate
```

### 3. Restart Workers
If you're running workers separately, restart them:
```bash
bundle exec rake seek:workers:restart
```

For Docker deployments, restart the seek_workers container:
```bash
docker-compose restart seek_workers
```

## What Stays the Same

- All rake tasks remain unchanged: `rake seek:workers:start`, `rake seek:workers:stop`, `rake seek:workers:restart`
- Admin interface for restarting workers remains the same
- Queue names and job priorities remain the same
- Job execution behavior remains the same (single retry, 24-hour timeout)

## Monitoring

### Sidekiq Web UI (Optional)

Sidekiq provides a web interface for monitoring jobs. To enable it, you can mount it in your routes.rb:

```ruby
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```

**Note:** Make sure to protect this route with authentication in production!

### Logs

Sidekiq logs are written to `log/sidekiq.log` (instead of the previous delayed_job logs).

### Checking Status

Check if Sidekiq is running:
```bash
bundle exec rake seek:workers:status
```

## Troubleshooting

### "Connection refused" errors
- Ensure Redis is running: `redis-cli ping`
- Check REDIS_URL environment variable is set correctly

### Jobs not processing
- Check Sidekiq is running: `bundle exec rake seek:workers:status`
- Check Sidekiq logs: `tail -f log/sidekiq.log`
- Check Redis is accessible: `redis-cli ping`

### Migration Issues
If you encounter issues with the migration:
1. Ensure all old delayed_job workers are stopped
2. Ensure Redis is running
3. Check the logs for specific error messages

## Rolling Back

If you need to roll back to delayed_job:
1. Restore the previous version of the code
2. Run `bundle install`
3. Restart the application and workers

Note: Any jobs that were queued in Redis will need to be re-queued.
