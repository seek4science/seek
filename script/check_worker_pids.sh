#!/bin/bash

expected_workers=$(bundle exec rails runner "puts Seek::Workers.active_queues.count")

shopt -s nullglob || true 2>/dev/null

# Fails if the number of running worker PID files is less than expected_workers
pid_files=(tmp/pids/delayed_job.*.pid)
pids=$(cat "${pid_files[@]}")
running_workers=$(echo "$pids" 2>/dev/null | wc -l)
if [ "$running_workers" -ne "$expected_workers" ]; then
  echo "Expected at least $expected_workers workers, but found $running_workers."
  exit 1
else
  for pid in $pids; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "Worker with PID $pid is not running."
      exit 1
    fi
  done
fi

# Log success
echo "Found $running_workers running workers (Expected: $expected_workers)."
exit 0