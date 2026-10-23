#!/bin/sh

# Starts a standalone SeaweedFS container as the S3-compatible store for native development
# (bundle exec rails server). Matches the development section of config/seek_storage.yml:
#   endpoint http://localhost:8333, bucket seek-dev, credentials seek / seek1234
# The credentials come from docker/seaweedfs-s3-config.json. The bucket is created if missing.
#
# Ports published on the host:
#   8333 -> 8333  S3 API            (what seek_storage.yml points at)
#   8888 -> 8888  Filer UI          http://localhost:8888/buckets/
#   9333 -> 9333  Master UI / API   http://localhost:9333/


set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
IDENTITY_FILE="$REPO_ROOT/docker/seaweedfs-s3-config.json"
IMAGE="${SEAWEEDFS_IMAGE:-chrislusf/seaweedfs}"
BUCKET="${SEEK_STORAGE_BUCKET:-seek-dev}"

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -qw seek-seaweedfs
then
    echo "container named seek-seaweedfs is already running"
    exit 1
fi

if [ ! -f "$IDENTITY_FILE" ]
then
    echo "missing $IDENTITY_FILE"
    exit 1
fi

if ! (docker volume ls | grep -q seek-seaweedfs-data-volume)
then
  echo "creating seek-seaweedfs-data-volume"
  docker volume create --name=seek-seaweedfs-data-volume
fi

docker rm seek-seaweedfs > /dev/null 2>&1 || true
echo "creating and starting seek-seaweedfs container ($IMAGE)"
docker run -d --name seek-seaweedfs --restart=unless-stopped \
    -p 8333:8333 -p 8888:8888 -p 9333:9333 \
    -v "seek-seaweedfs-data-volume:/data" \
    -v "$IDENTITY_FILE:/etc/seaweedfs/s3.json:ro" \
    "$IMAGE" server -s3 -s3.config=/etc/seaweedfs/s3.json -dir /data

echo "waiting for SeaweedFS to be ready ..."
retries=0
until docker exec seek-seaweedfs sh -c 'curl -sf http://localhost:9333/cluster/status >/dev/null && curl -sf http://localhost:8888/ >/dev/null' 2>/dev/null; do
    sleep 1
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "SeaweedFS did not become ready within 60 seconds"
        exit 1
    fi
done

# s3.bucket.* commands run against the filer, so -filer is required.
if echo "s3.bucket.list" | docker exec -i seek-seaweedfs weed shell -master=localhost:9333 -filer=localhost:8888 2>/dev/null | grep -qw "$BUCKET"
then
    echo "bucket $BUCKET already exists"
else
    echo "creating bucket $BUCKET"
    echo "s3.bucket.create -name $BUCKET" | docker exec -i seek-seaweedfs weed shell -master=localhost:9333 -filer=localhost:8888 > /dev/null
fi

echo "SeaweedFS is ready"
echo "  S3 API:   http://localhost:8333  (bucket: $BUCKET)"
echo "  Filer UI: http://localhost:8888/buckets/"
