# SeaweedFS Standalone — Native SEEK Development Guide

For developers who run SEEK natively on their machine (`bundle exec rails server`) rather
than in the full container stack. You don't need MySQL/Solr/Redis containers — you just
need an S3-compatible object store to exercise the S3 storage backend. This guide runs
**only SeaweedFS** in a single container and points your development SEEK at it.

> Want the full containerised stack (SEEK + workers + DB + Solr + Redis + SeaweedFS)
> instead? See the companion guide `docker_s3_setup_guide.md`.

---

## 1. Prerequisites

- Docker (only used to run the SeaweedFS container).
- A working native SEEK development setup on the `s3-support` branch (Ruby/Rails, MySQL
  or your usual dev DB, `bundle install` done, etc.).
- Optional: the AWS CLI, for inspecting the bucket from the terminal.

---

## 2. The wiring is already in the branch

The `development` section of `config/seek_storage.yml` is preconfigured for S3 against a
local SeaweedFS, so once the store is running SEEK will use it automatically:

```yaml
development:
  backend: s3
  bucket: seek-dev
  region: us-east-1
  access_key_id: seek
  secret_access_key: seek1234
  endpoint: http://localhost:9000
  force_path_style: true
```

Notes:

- There is **no** `public_endpoint` here on purpose — SEEK and your browser both reach the
  store at `localhost:9000`, so one endpoint is enough. (`public_endpoint` only matters
  when the app and the browser see the store at different addresses, i.e. the compose /
  reverse-proxy case.)
- To fall back to local-disk storage instead, uncomment `<<: *default` and comment out the
  `backend: s3` block.

---

## 3. Step 1 — Provide the S3 identity config

The standalone container reads its credentials from a JSON file. It defines who may access
the S3 API and with what key — this is the **store's** side of the credential, and it must
match the `access_key_id` / `secret_access_key` in `seek_storage.yml` above.

The repo already ships this file at `docker/seaweedfs-s3-config.json` (its `seek`/`seek1234`
identity already matches the dev config), so you don't need to create or copy anything — the
`docker run` command below mounts it straight from the repo. Just make sure you run that
command **from the repo root** so `$(pwd)/docker/...` resolves correctly.

For reference, the file looks like:

```json
{
  "identities": [
    {
      "name": "seek",
      "credentials": [
        { "accessKey": "seek", "secretKey": "seek1234" }
      ],
      "actions": ["Admin", "Read", "Write"]
    }
  ]
}
```

---

## 4. Step 2 — Start SeaweedFS

Run this **from the repo root** (the `-v` source must be an absolute path, which
`$(pwd)/docker/...` provides):

```sh
#!/bin/sh
docker run -d -p 9000:8333 -p 9333:9333 -p 8080:8080 -p 8888:8888 \
    --name=seaweedfs -v "seaweedfs-data:/data" \
    -v "$(pwd)/docker/seaweedfs-s3-config.json:/etc/seaweedfs/s3.json" \
  chrislusf/seaweedfs server -s3 -s3.config=/etc/seaweedfs/s3.json -dir /data
```

Port mapping in this command:

| Published port | SeaweedFS port | What |
|---|---|---|
| `9000` | `8333` | **S3 API** — this is what `endpoint: http://localhost:9000` points at |
| `9333` | `9333` | Master UI / API (`weed shell` talks to this) |
| `8080` | `8080` | Volume server |
| `8888` | `8888` | **Filer UI** — browse stored objects at http://localhost:8888/buckets/ |


## 5. Step 3 — Create the bucket

SeaweedFS does not auto-create buckets, and the standalone `docker run` has no init job to
do it for you. Create the `seek-dev` bucket once:

```bash
echo "s3.bucket.create -name seek-dev" | \
  docker exec -i seaweedfs weed shell -master=localhost:9333 -filer=localhost:8888
```

> The `-filer=localhost:8888` flag is required — `s3.bucket.*` commands run against the
> filer, and without it `weed shell` fails with `missing address`. (The bucket persists in
> the `seaweedfs-data` volume, so you only need this once, not on every container restart.)

Confirm it exists:

```bash
echo "s3.bucket.list" | \
  docker exec -i seaweedfs weed shell -master=localhost:9333 -filer=localhost:8888
```

---

## 6. Step 4 — Run SEEK and verify

Start SEEK in development as usual:

```bash
bundle exec rails server
```

Upload a file through the UI, then confirm it landed in the store — via the filer UI at
http://localhost:8888/buckets/seek-dev/, or the AWS CLI:

```bash
aws --endpoint-url http://localhost:9000 s3 ls s3://seek-dev/assets/
```

You should see an object named `<uuid>.dat` under the `assets/` prefix, confirming SEEK
wrote to S3 rather than the local disk filestore.

---

## 7. Managing the container

```bash
docker stop seaweedfs             # stop
docker start seaweedfs            # start again (data persists in the seaweedfs-data volume)
docker rm -f seaweedfs            # remove the container
docker volume rm seaweedfs-data   # wipe stored objects (then recreate the bucket, §5)
```


