#!/bin/bash

min_workers=${MIN_WORKERS:-1}

# Check whether min_workers is a valid number greater than or equal to 1
if ! [[ "$min_workers" =~ ^[0-9]+$ ]] || [ "$min_workers" -lt 1 ]; then
  echo "MIN_WORKERS is not a valid number greater than or equal to 1: $min_workers"
  exit 1
fi

# Fails if the number of running worker PID files is less than min_workers
running_workers=$(ls tmp/pids/delayed_job*.pid 2>/dev/null | wc -l)
if [ "$running_workers" -lt "$min_workers" ]; then
  echo "Expected at least $min_workers workers, but found $running_workers."
  exit 1
fi

# Log success
echo "Found $running_workers running workers (minimum required: $min_workers)."
exit 0