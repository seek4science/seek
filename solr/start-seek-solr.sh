#!/bin/bash
#
# Starts Solr with the SEEK core, creating it from the baked-in configset on first run.
#
# solr-precreate only copies the configset when the core does not exist yet, so on a persistent
# volume an existing core would keep the configuration it was created with. To make configuration
# changes ship with the image, an existing core's conf directory is replaced with the configset on
# every start. The index itself (the core's data directory) is left untouched; changes that affect
# indexing need a reindex, which seek:upgrade performs.

set -euo pipefail

CORE=seek
CONFIGSET=/opt/solr/server/solr/configsets/seek_config
CORE_DIR="/var/solr/data/$CORE"

if [ -d "$CORE_DIR" ]; then
  echo "Refreshing $CORE core configuration from $CONFIGSET"
  rm -rf "$CORE_DIR/conf"
  cp -r "$CONFIGSET/conf" "$CORE_DIR/conf"
fi

exec solr-precreate "$CORE" "$CONFIGSET"
