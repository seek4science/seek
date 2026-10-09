# Solr with the SEEK configset baked in, for deployments where the configset can't be bind-mounted
# from the repository as docker-compose.yml does (e.g. a dedicated cloud instance).
#
# Build from the solr directory:
#   docker build -t fairdom/seek-solr:<seek-version> solr
#
# The core's index lives in /var/solr, which should be a persistent volume.
FROM solr:9.10.1

COPY seek/conf /opt/solr/server/solr/configsets/seek_config/conf
COPY --chmod=755 start-seek-solr.sh /opt/solr/docker/scripts/start-seek-solr.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=6 \
  CMD curl -sf http://localhost:8983/solr/seek/admin/ping || exit 1

CMD ["/opt/solr/docker/scripts/start-seek-solr.sh"]
