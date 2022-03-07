#!/bin/sh

#30 minutes
MAX_SECS=1800

COMMAND="soffice.bin"

pids=$(ps -eo etimes,pid,comm | awk -v max_secs=$MAX_SECS -v command=$COMMAND '{if ($3 == command && $1 >= max_secs) print $2}')

if [ ! -z "$pids" ]
then
  kill $pids
fi