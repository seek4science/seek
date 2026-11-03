# S3 storage support in SEEK

SEEK stores uploaded files through a small storage layer with two interchangeable backends. The default
writes files to the local filesystem under `filestore/`. The S3 backend stores them in any S3-compatible
object store instead: AWS S3, MinIO, SeaweedFS, DigitalOcean Spaces and similar services.

This document covers how the two backends differ, how to configure S3, how to move an existing
installation to it, and what the S3 backend needs from the store for direct browser uploads.

---

## Architecture

Two adapter classes share the same public interface, so the rest of the application does not know which
backend is in use:

| Adapter | File |
|---------|------|
| `Seek::Storage::LocalAdapter` | `lib/seek/storage/local_adapter.rb` |
| `Seek::Storage::S3Adapter` | `lib/seek/storage/s3_adapter.rb` |

`Seek::Storage` (`lib/seek/storage.rb`) reads `config/seek_storage.yml`, validates the configuration at
boot and hands out memoised adapter instances.

Each `ContentBlob` uses two adapters, one for the original file and one for derived formats:

| Role | Local directory setting | S3 key prefix | Formats stored |
|------|-------------------------|---------------|----------------|
| Asset (original uploads) | `asset_filestore_path` | `assets/` | `.dat` |
| Converted (derivatives) | `converted_filestore_path` | `converted/` | `.pdf`, `.txt` |

On the S3 backend a third prefix, `uploads/`, is a staging area for files the browser sends straight to
the store (see "Direct browser upload" below). Nothing permanent lives there.

Storage keys are UUID based: `<uuid>.dat`, `<uuid>.pdf`, `<uuid>.txt`.

---

## Configuration

Edit `config/seek_storage.yml`. The file has one section per Rails environment.

### Local filesystem (default)

```yaml
default: &default
  backend: local
```

### AWS S3

```yaml
production:
  <<: *default
  backend: s3
  bucket: my-seek-bucket
  region: eu-west-1
  access_key_id: AKIA...
  secret_access_key: wJalr...
```

### MinIO, SeaweedFS or other S3-compatible services

```yaml
production:
  <<: *default
  backend: s3
  bucket: seek-production
  region: us-east-1
  access_key_id: seek
  secret_access_key: ...
  endpoint: http://minio:9000
  force_path_style: true   # required for MinIO, SeaweedFS and most compatible services
```

### All S3 configuration keys

| Key | Required | Default | Notes |
|-----|----------|---------|-------|
| `bucket` | yes | — | The bucket must already exist |
| `access_key_id` | yes | — | |
| `secret_access_key` | yes | — | |
| `region` | no | `us-east-1` | |
| `endpoint` | no | AWS endpoint | The address SEEK uses to reach the store. Set it for non-AWS services |
| `public_endpoint` | no | same as `endpoint` | The address browsers use to reach the store, when that differs from `endpoint` (for example an internal Docker hostname versus a public one). Used only to sign the URLs handed to browsers |
| `force_path_style` | no | `false` | Set `true` for MinIO and SeaweedFS |

The production section of the shipped `config/seek_storage.yml` reads all of these from `SEEK_STORAGE_*`
environment variables, so the same Docker image can run against local disk or an object store without a
rebuild. `docker/s3.env` shows the full set for the `docker-compose-s3.yml` stack.

Configuration is validated at boot (`config/initializers/seek_storage.rb`). Missing required keys raise
`Seek::Storage::ConfigurationError` immediately.

---

## How downloads work

The key difference between backends is that S3 has no filesystem path:

```
LocalAdapter#full_path(key)  →  "/data/assets/uuid.dat"
S3Adapter#full_path(key)     →  nil
```

Controllers branch on this. On the local backend the file is served with `send_file`. On S3 the default
is a redirect to a presigned URL, so the bytes travel from the store to the browser without passing
through SEEK:

```ruby
# lib/seek/content_blob_common.rb
local_path = adapter.full_path(key)
if local_path
  send_file local_path, ...                                   # local: serve directly
elsif params[:stream].present?
  stream_blob_through_app(adapter, key, ...)                  # S3: proxy through SEEK on request
else
  redirect_to adapter.presigned_url(key, expires_in: 300), allow_other_host: true   # S3: redirect
end
```

Presigned download URLs expire after **300 seconds** (5 minutes). Adding `?stream=1` to a download URL
makes SEEK stream the object itself instead of redirecting, for clients that cannot follow a redirect to
another host.

---

## Direct browser upload

On the S3 backend, uploads also stay out of SEEK's data path. When a user picks a file in an asset form
(data files, SOPs, models, presentations, documents, file templates, publication full text), the
browser:

1. asks SEEK for a signed upload URL (`POST /content_blobs/direct_upload`, valid for 15 minutes, one URL
   per file),
2. sends the file straight to the store with an HTTP `PUT`, under the `uploads/` prefix, showing a
   progress bar,
3. submits the form with only the staging key, not the file.

When the form is saved, SEEK checks that the staged object exists and is not empty, copies it server-side
to its permanent `assets/<uuid>.dat` key and deletes the staged copy. New versions of an asset work the
same way. If the signed URL cannot be obtained, the browser falls back to sending the file through the
form as before.

Direct upload is on whenever the backend is `s3`. It is switched off together with normal uploads by the
`block_file_uploads` setting, and nothing changes on the local backend. It is not used for avatars and
model images (SEEK must receive those to resize them), for workflows, or for imports that are parsed
rather than stored.

A single `PUT` can carry at most 5 GB; larger files are not supported through the browser yet.

### The store must allow CORS

The page comes from SEEK's address and the file goes to the store's address, so the browser applies its
cross-origin rule (CORS). Before sending the file it sends an `OPTIONS` request, called a preflight, to
the store, asking whether a `PUT` with a `Content-Type` header from the SEEK origin is allowed. **If the
store does not say yes, the upload fails in the browser with a bare network error and nothing appears in
SEEK's logs.** This is store configuration, not SEEK configuration.

Check it from any machine:

```bash
curl -si -X OPTIONS https://s3.example.org/<bucket>/uploads/x \
     -H 'Origin: https://seek.example.org' \
     -H 'Access-Control-Request-Method: PUT' \
     -H 'Access-Control-Request-Headers: content-type'
```

A working store answers `200` with `Access-Control-Allow-Origin: https://seek.example.org` (or `*`), an
`Access-Control-Allow-Methods` list containing `PUT`, and `Access-Control-Allow-Headers` containing
`content-type`.

**Development.** The dev stack (`script/start-docker-seaweedfs.sh`, `docker-compose-s3.yml`) runs
SeaweedFS, whose S3 gateway allows every origin by default (`-s3.allowedOrigins="*"`, checked against
4.48). Nothing to configure. If uploads stop working after a SeaweedFS upgrade, run the check above first.

**Production.** Allow only the SEEK origin, the `PUT` method and the `Content-Type` header. Nothing else is
needed: downloads are plain redirects and do not go through CORS.

| Store | How |
|---|---|
| **SeaweedFS** | Start the S3 gateway with `-s3.allowedOrigins=https://seek.example.org` (`weed server`) or `-allowedOrigins=...` (`weed s3`). Several origins: comma-separated. |
| **MinIO** | Set `MINIO_API_CORS_ALLOW_ORIGIN=https://seek.example.org` in the server environment (comma-separated for several; the default is `*`). |
| **AWS S3** | Put a CORS configuration on the bucket (Console → Permissions → CORS, or `aws s3api put-bucket-cors`): |

```json
[
  {
    "AllowedOrigins": ["https://seek.example.org"],
    "AllowedMethods": ["PUT"],
    "AllowedHeaders": ["Content-Type"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

### A reverse proxy in front of the store

If browsers reach the store through a reverse proxy (the usual setup: a dedicated subdomain in front of
MinIO or SeaweedFS), set `public_endpoint` to that public address and make sure the proxy:

1. **lets `OPTIONS` through** to the store rather than answering or blocking it,
2. **has no request body limit** (nginx's `client_max_body_size` defaults to 1 MB),
3. **does not buffer the request body to disk** (`proxy_request_buffering off`),
4. **has long timeouts**, since a multi-GB `PUT` on a slow link runs for minutes,
5. **keeps the `Host` header unchanged**, because the signature on both presigned GETs and PUTs covers it.

```nginx
server {
    listen 443 ssl;
    server_name s3.example.org;

    location / {
        proxy_pass http://localhost:8333;
        proxy_set_header Host $host;        # signature check (GET and PUT alike)
        client_max_body_size 0;             # presigned PUT carries the whole file
        proxy_request_buffering off;        # stream, do not spool to disk
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        # Do not add CORS headers here; the store sets them and duplicates break the preflight.
    }
}
```

Use `https://` for `public_endpoint` when SEEK itself is served over HTTPS, otherwise browsers block the
upload as mixed content.

---

## Cleaning the direct-upload staging area

A browser upload lands under `uploads/` and is moved to `assets/` when the form is submitted. If the form
is never submitted (tab closed, session expired, validation failed and the page abandoned), the object
stays under `uploads/` with nothing pointing at it. Two ways to remove such leftovers; use either or both.

### Built in: scheduled job and rake task

`StaleDirectUploadCleanupJob` deletes every object under `uploads/` older than **24 hours**. On the local
backend it does nothing. Anything younger is left alone: a signed upload URL lives 15 minutes, but a form
with an uploaded file may sit open on someone's screen for a while before they press Save.

The job is scheduled in `config/recurring.yml` (01:20 UTC daily in production), which is read by the
Solid Queue scheduler started by `bin/jobs`. On installations that still run Delayed Job instead of
Solid Queue, `recurring.yml` is not read: run the rake task below from cron instead.

The same cleanup can be run by hand:

```bash
bundle exec rake seek:storage:purge_stale_uploads DRY_RUN=1        # list what would go, delete nothing
bundle exec rake seek:storage:purge_stale_uploads                  # delete objects older than 24 h
bundle exec rake seek:storage:purge_stale_uploads MAX_AGE_HOURS=6  # a different limit
```

It prints one line per stale object and a summary such as
`Staging area: 7 object(s) examined, 6 older than the limit, 6 deleted.`

### Alternative: a lifecycle rule on the bucket

Stores that support S3 lifecycle rules can expire the prefix themselves, with no SEEK process involved.
Expiration is by whole days, so the shortest rule is one day. The built-in job is still safe to leave on;
it will simply find nothing.

| Store | How |
|---|---|
| **AWS S3** | Console → bucket → Management → Lifecycle rule, prefix `uploads/`, expire current versions after 1 day. Or `aws s3api put-bucket-lifecycle-configuration` with the JSON below. |
| **MinIO** | `mc ilm rule add --expire-days 1 --prefix uploads/ myminio/<bucket>` |
| **SeaweedFS** | Accepts the same `PutBucketLifecycleConfiguration` call as AWS. Whether expiry is enforced on schedule has not been verified; keep the built-in job on. |

```json
{
  "Rules": [
    {
      "ID": "expire-abandoned-direct-uploads",
      "Filter": { "Prefix": "uploads/" },
      "Status": "Enabled",
      "Expiration": { "Days": 1 }
    }
  ]
}
```

Only `uploads/` may carry such a rule. `assets/` and `converted/` hold real data and must never expire.

---

## How content conversion works (PDF / text extraction)

Conversion tools (LibreOffice, Docsplit) need a local file path. When the backend is S3, SEEK streams the
object to a `Tempfile` first:

```ruby
# app/models/content_blob.rb
def with_temporary_copy_of_converted(format)
  local = storage_adapter(format).full_path(storage_key(format))
  if local
    yield local
  else
    Tempfile.create(...) do |tmp|
      IO.copy_stream(storage_adapter(format).open(...), tmp)
      yield tmp.path
    end
  end
end
```

The same pattern is used when building ZIP archives containing several blobs.

---

## Verifying the connection

```bash
bundle exec rake seek:storage:test
```

For S3 this performs a read-only `list_objects_v2` (max 1 key) and reports success, or one of:

- `Bucket 'name' does not exist`
- `Access denied to bucket 'name'. Check access_key_id and secret_access_key.`
- `Cannot connect to S3 endpoint: <error>`

The admin home page also shows the active backend and the non-sensitive S3 settings (bucket, region,
endpoint). Credentials are never displayed.

---

## Migrating existing files from local to S3

When switching a running installation to S3, copy the existing files first. The tasks are idempotent and
never delete or modify local files, so they can run while the installation is still on the local backend
and be re-run until the switch.

### Dry run (nothing is uploaded)

```bash
bundle exec rake seek:storage:copy_local_to_s3 DRY_RUN=1
```

### Live migration

```bash
bundle exec rake seek:storage:copy_local_to_s3        # content blobs: originals, PDFs, text extractions
bundle exec rake seek:storage:copy_fleximage_to_s3    # avatar and model image master files
```

Each prints a summary such as:

```
Copied: 42  Skipped: 10  Missing: 2  Failed: 0
```

- **Skipped**: already on S3 with matching size. Safe to rerun.
- **Missing**: local file not found. Counted; the migration continues.
- **Failed**: an S3 object with the same key has a different size (possible partial upload). Not
  overwritten; fix by hand.

The underlying class can also be used from the Rails console:

```ruby
migrator = Seek::Storage::LocalToS3Migrator.new(dry_run: false)
result   = migrator.run
puts result.summary
```

---

## Local development stack

`script/start-docker-seaweedfs.sh` starts a single SeaweedFS container exposing the S3 API on port 8333,
a file browser on port 8888 (`http://localhost:8888/buckets/`) and the master UI on port 9333, and creates
the `seek-dev` bucket. It matches the development section of `config/seek_storage.yml`.
`docker-compose-s3.yml` runs the full production-style stack (SEEK, workers, MySQL, Solr, Redis,
SeaweedFS) with the values from `docker/s3.env`.

---

## Dependencies

```ruby
# Gemfile
gem 'aws-sdk-s3', require: false
```

The gem is loaded only when the S3 backend is configured.

---

## Test coverage

| Test file | Coverage |
|-----------|----------|
| `test/unit/seek/s3_adapter_test.rb` | Write, read, exist?, size, delete, copy, listing, presigned download and upload URLs, connection testing |
| `test/unit/seek/storage_test.rb` | Configuration validation, error messages, credential redaction, staging adapter |
| `test/unit/seek/local_to_s3_migrator_test.rb` | Copy, skip, dry run, size-mismatch failure, idempotency |
| `test/unit/seek/fleximage_to_s3_migrator_test.rb` | The same for avatar and model image files |
| `test/unit/upload_handling_test.rb` | Accepting a staged upload, refusing missing or empty objects, local backend and blocked uploads |
| `test/unit/seek/stale_upload_cleaner_test.rb`, `test/unit/jobs/stale_direct_upload_cleanup_job_test.rb` | Staging area cleanup |
| `test/functional/content_blobs_controller_test.rb` | Signed upload URL endpoint and its refusals; downloads by redirect and by streaming |
| `test/functional/data_files_controller_test.rb` | Form markup per backend, creating assets and versions from a staged upload |
