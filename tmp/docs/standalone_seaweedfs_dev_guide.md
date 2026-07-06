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

Copy the repo's version to `$HOME/bin/seaweedfs-s3-config.json` (its `seek`/`seek1234`
identity already matches the dev config):

```bash
mkdir -p "$HOME/bin"
cp docker/seaweedfs-s3-config.json "$HOME/bin/seaweedfs-s3-config.json"
```

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

```sh
#!/bin/sh
docker run -d -p 9000:8333 -p 9333:9333 -p 8080:8080 \
    --name=seaweedfs -v "seaweedfs-data:/data" \
    -v "$HOME/bin/seaweedfs-s3-config.json:/etc/seaweedfs/s3.json" \
  chrislusf/seaweedfs server -s3 -s3.config=/etc/seaweedfs/s3.json -dir /data
```

Port mapping in this command:

| Published port | SeaweedFS port | What |
|---|---|---|
| `9000` | `8333` | **S3 API** — this is what `endpoint: http://localhost:9000` points at |
| `9333` | `9333` | Master UI / API (`weed shell` talks to this) |
| `8080` | `8080` | Volume server |

*(This command does not publish the filer UI. To browse stored objects in a browser, add
`-p 8888:8888` and open http://localhost:8888/buckets/.)*

---

## 5. Step 3 — Create the bucket

SeaweedFS does not auto-create buckets, and the standalone `docker run` has no init job to
do it for you. Create the `seek-dev` bucket once:

```bash
echo "s3.bucket.create -name seek-dev" | \
  docker exec -i seaweedfs weed shell -master=localhost:9333
```

---

## 6. Step 4 — Run SEEK and verify

Start SEEK in development as usual:

```bash
bundle exec rails server
```

Upload a file through the UI, then confirm it landed in the store — via the filer UI (if
you published 8888) or the AWS CLI:

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

---

## 8. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Uploads fail / "access denied" | The keys in `seaweedfs-s3-config.json` and `config/seek_storage.yml` (development) don't match. |
| `NoSuchBucket` on upload | You skipped §5 — create the `seek-dev` bucket. It doesn't persist if you delete the `seaweedfs-data` volume. |
| SEEK still writing to local disk | The `development` section of `seek_storage.yml` isn't set to `backend: s3` (or `<<: *default` is still active). |
| Connection refused to `localhost:9000` | The container isn't running, or the S3 port isn't mapped. Check `docker ps` — the mapping must be `9000:8333`. |
| Config change to `seek_storage.yml` not taking effect | Restart `rails server` — the storage config is read at boot. |

---

## 9. Notes

- **Resized avatars / model images** are cached on local disk (temporary filestore) and
  regenerated from the S3 master on demand — they aren't served from S3 directly.
- Some features (workflow diagram / RO-Crate extraction, git conversion) still read files
  from the local `filestore` and haven't been migrated to the S3 adapter yet. See
  `tmp/docs/s3_audit_report_2026-06-29.md` §5.
