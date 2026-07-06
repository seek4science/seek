# SEEK with S3 Storage — Docker Setup Guide

A step-by-step guide to running SEEK on the `s3-support` branch with an S3-compatible
object store. The provided `docker-compose-s3.yml` brings up SEEK plus a local
[SeaweedFS](https://github.com/seaweedfs/seaweedfs) store so you can test the S3 backend
end-to-end on your own machine — no AWS account or MinIO needed.

> Running SEEK natively (`bundle exec rails server`) instead of in containers? See the
> companion guide `standalone_seaweedfs_dev_guide.md` for running just SeaweedFS on its own.

---

## 1. What the stack contains

`docker-compose-s3.yml` starts these services:

| Service | Image | Role |
|---|---|---|
| `seek` | `fairdom/seek:s3-support` | The SEEK web app (port 3000) |
| `seek_workers` | `fairdom/seek:s3-support` | Background job workers (delayed_job) |
| `db` | `mysql:8.4` | Database |
| `solr` | `solr:8.11.4` | Full-text search |
| `redis_store` | `redis:8.6-alpine` | Session / cache store |
| `seaweedfs` | `chrislusf/seaweedfs` | **S3-compatible object store** (the file storage) |
| `seaweedfs-init` | `chrislusf/seaweedfs` | One-shot job that creates the storage bucket |

SEEK is configured (via `docker/s3.env`) to use the S3 backend, so uploaded files are
stored in SeaweedFS instead of the local disk filestore.

---

## 2. Prerequisites

- Docker with Compose v2 (`docker compose`, not the old `docker-compose`)
- The `s3-support` branch checked out:

  ```bash
  git checkout s3-support
  git pull
  ```

- Roughly 4 GB free RAM for the full stack.

---

## 3. Configuration files (already provided — no editing needed for local use)

You don't need to change anything to run locally. For reference, the settings live in:

**`docker/s3.env`** — tells SEEK how to reach the store:

```
SEEK_STORAGE_BACKEND=s3
SEEK_STORAGE_BUCKET=seek-dev
SEEK_STORAGE_REGION=us-east-1
SEEK_STORAGE_ACCESS_KEY_ID=seek
SEEK_STORAGE_SECRET_ACCESS_KEY=seek1234
SEEK_STORAGE_ENDPOINT=http://seaweedfs:8333        # internal address SEEK uses
SEEK_STORAGE_PUBLIC_ENDPOINT=http://localhost:9000 # address the browser uses for downloads
SEEK_STORAGE_FORCE_PATH_STYLE=true                 # required for SeaweedFS/MinIO
```

**`docker/seaweedfs-s3-config.json`** — the store's side of the same credential
(access key `seek` / secret `seek1234`). These **must match** `docker/s3.env`.

> **Why two endpoints?** `SEEK_STORAGE_ENDPOINT` is how the SEEK container reaches
> SeaweedFS inside the Docker network. `SEEK_STORAGE_PUBLIC_ENDPOINT` is the address
> baked into the presigned download links handed to your browser — your browser can't
> resolve the internal `seaweedfs` hostname, so downloads use `localhost:9000` instead.

---

## 4. First-time setup

### Step 1 — Create the named volumes

The compose file declares its volumes as `external: true`, meaning Docker will **not**
create them automatically. Create them once:

```bash
docker volume create seek-filestore
docker volume create seek-mysql-db
docker volume create seek-solr-data
docker volume create seek-cache
docker volume create seek-redis-data
docker volume create seek-seaweedfs-data
```

*(If you skip this, `docker compose up` fails immediately with an "external volume not
found" error.)*

### Step 2 — Start the stack

```bash
docker compose -f docker-compose-s3.yml up
```

Add `-d` to run detached (in the background):

```bash
docker compose -f docker-compose-s3.yml up -d
```

### What happens on first boot

1. MySQL, Redis, Solr, and SeaweedFS start and become healthy.
2. `seaweedfs-init` runs once and creates the `seek-dev` bucket (SeaweedFS does **not**
   auto-create buckets on first write).
3. The `seek` container starts. Because the database is empty, its entrypoint
   automatically runs `rake db:setup` to create and seed the schema. **No manual DB
   step is required.**
4. Workers, cron, and nginx start; SEEK becomes reachable.

First boot takes a few minutes (image pull + DB setup + asset checks). Watch the logs
until you see SEEK responding on port 3000.

---

## 5. Access points

| URL | What |
|---|---|
| http://localhost:3000 | **SEEK web app** |
| http://localhost:8888/buckets/ | SeaweedFS **filer UI** — browse the objects SEEK has stored |
| http://localhost:9333/ | SeaweedFS master / cluster status |
| http://localhost:9000 | Raw S3 API endpoint (browser-facing) |

Default admin login for a freshly seeded SEEK is created during first-run setup — follow
the on-screen "register the first admin" flow at http://localhost:3000 if prompted.

---

## 6. Verifying S3 storage works

1. Log in and upload a Data file (Create → Data file → upload any file).
2. Open the SeaweedFS filer UI: http://localhost:8888/buckets/seek-dev/
3. You should see the object under the `assets/` prefix, named `<uuid>.dat`. That
   confirms the file went to S3, not the local disk filestore.
4. Download the file back from SEEK. The download is a redirect to a **presigned URL**
   on `localhost:9000` — if it downloads successfully, the `public_endpoint` wiring is
   correct.

---

## 7. Everyday commands

```bash
# Follow logs
docker compose -f docker-compose-s3.yml logs -f seek

# Stop (keeps data in volumes)
docker compose -f docker-compose-s3.yml down

# Restart
docker compose -f docker-compose-s3.yml up -d

# Open a Rails console inside the app container
docker compose -f docker-compose-s3.yml exec seek bundle exec rails console

# Full reset — WIPES all data (DB, search, uploaded files)
docker compose -f docker-compose-s3.yml down
docker volume rm seek-filestore seek-mysql-db seek-solr-data \
  seek-cache seek-redis-data seek-seaweedfs-data
# then recreate the volumes (Step 1) and start again
```

---

## 8. Testing your own code changes (instead of the pre-built image)

By default the stack runs the published `fairdom/seek:s3-support` image, so it does **not**
reflect your local working tree. To build and run your own checkout instead, edit
`docker-compose-s3.yml`:

```yaml
x-shared:
  seek_base: &seek_base
    build: .                          # <-- uncomment this
    # image: fairdom/seek:s3-support  # <-- comment this out
```

Then rebuild:

```bash
docker compose -f docker-compose-s3.yml up --build
```

---

## 9. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `external volume "seek-…" not found` | You skipped Step 1. Run the `docker volume create` commands. |
| Uploads fail / "access denied" from the store | Keys in `docker/s3.env` and `docker/seaweedfs-s3-config.json` don't match. |
| Upload succeeds but **download** fails / times out | `SEEK_STORAGE_PUBLIC_ENDPOINT` must be an address your **browser** can reach (`http://localhost:9000` locally). The internal `seaweedfs:8333` will not work from a browser. |
| No object appears in the bucket after upload | Check the `seaweedfs-init` job completed (`docker compose -f docker-compose-s3.yml ps -a`) — the `seek-dev` bucket must exist first. |
| SEEK stuck on "WAITING FOR DATABASE" | MySQL is still initializing on first boot; give it a minute. Persistent failure usually means a stale/corrupt `seek-mysql-db` volume — reset it. |

---

## 10. Notes and known limitations

- **Local filestore is still mounted.** Some features (workflow diagram / RO-Crate
  extraction, git conversion) still read files from the local `filestore` and haven't
  been migrated to the S3 adapter yet. That's why the `seek-filestore` volume remains in
  the compose file. See `tmp/docs/s3_audit_report_2026-06-29.md` §5.
- **Resized avatars / model images** are cached on the local disk (temporary filestore)
  and regenerated from the S3 master on demand — they are not served from S3 directly.
- **For production** behind a reverse proxy, see
  `tmp/docs/s3_reverse_proxy_deployment_notes_2026-07-03.md` — in particular the
  requirement that the proxy preserve the `Host` header for presigned URLs to validate.
