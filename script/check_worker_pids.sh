#!/bin/bash

# Solid Queue's supervisor forks its own worker/dispatcher/scheduler subprocesses
# internally (per config/queue.yml), so unlike the old per-queue delayed_job pidfile
# check, checking the single supervisor pidfile is sufficient here.
pid=$(bundle exec rails runner "puts Seek::Util.solid_queue_supervisor_pid")

if [ -z "$pid" ]; then
  echo "Solid Queue supervisor is not running."
  exit 1
fi

echo "Solid Queue supervisor running (Process ID: $pid)."
exit 0
