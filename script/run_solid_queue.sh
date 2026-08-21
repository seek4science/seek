#!/bin/bash
# Runs the Solid Queue supervisor (bin/jobs) in a loop that restarts it if it
# exits - e.g. after the admin "Restart background job workers" button
# (AdminController#restart_job_workers) sends SIGTERM to the supervisor's own
# pidfile (config/initializers/solid_queue.rb).
#
# Sending SIGTERM/SIGINT to *this script's own* PID (recorded in
# tmp/pids/solid_queue_runner.pid), rather than the supervisor's, stops it for
# good instead of restarting it - used by deployment scripts that need a clean
# stop before restarting later (see script/update-from-git.sh).
mkdir -p tmp/pids
echo $$ > tmp/pids/solid_queue_runner.pid

child_pid=""
stop=0
trap 'stop=1; [ -n "$child_pid" ] && kill -TERM "$child_pid" 2>/dev/null' TERM INT

while [ "$stop" -eq 0 ]; do
  bundle exec bin/jobs &
  child_pid=$!
  wait "$child_pid"
  child_pid=""
  if [ "$stop" -eq 0 ]; then
    echo "Solid Queue supervisor exited, restarting in 1s..."
    sleep 1
  fi
done

rm -f tmp/pids/solid_queue_runner.pid
