# S3 Storage Support — Audit & Status Report

**Branch:** `s3-support` (41 commits ahead of `main`, incl. merges of `main` / `seek-1.18`) · **Date:** 2026-06-29 · **Tested against:** local MinIO

## 1. What this is

SEEK assumed every uploaded file lives on the local filesystem (`content_blob.filepath`). This branch
makes file handling **backend-agnostic** so all research files can live in S3-compatible object
storage. A pluggable `Seek::Storage` layer (`LocalAdapter` / `S3Adapter`, chosen in
`config/seek_storage.yml`) sits under `ContentBlob`. **No DB schema change** — the object key is
derived from the existing blob `uuid`; the backend is config-only.

The recurring fix is one of two patterns:
- **Reads** that need a real file → `content_blob.with_temporary_copy { |path| … }` (streams a temp copy from S3, auto-deleted).
- **Writes / downloads** → through the adapter (`storage_adapter.write` / presigned URL / streamed response).

## 2. How it's implemented (for developers)

### 2.1 The adapter layer
`Seek::Storage` (`lib/seek/storage.rb`) is a small factory. `Seek::Storage.adapter_for(format)` returns
one of two backends, chosen at boot from `config/seek_storage.yml` (`backend: local` | `s3`):

- **`LocalAdapter`** (`lib/seek/storage/local_adapter.rb`) — thin wrapper over `File`/`FileUtils`.
- **`S3Adapter`** (`lib/seek/storage/s3_adapter.rb`) — same interface over the `aws-sdk-s3` client (works with AWS S3 or MinIO via `endpoint` + `force_path_style`).

Both expose the **same interface**, so callers never branch on backend:

| Method | Purpose |
|---|---|
| `write(key, content)` | Store a String or IO. |
| `copy_from_path(src, key)` | Upload an existing local file (S3: `put_object`; local: `cp`). |
| `open(key)` | Return a readable IO of the full object. |
| `stream(key) { \|chunk\| }` | Yield the object in chunks without buffering it all (used for COPASI/Morpheus downloads). |
| `exist?(key)` / `size(key)` / `delete(key)` | Existence / size / delete. |
| `full_path(key)` | **Local:** absolute on-disk path. **S3:** `nil`. |
| `presigned_url(key, …)` | **S3 only:** signed, time-limited GET URL with filename/content-type overrides. |
| `test_connection` | Read-only connectivity check (admin UI). |

Two adapter instances exist per process, one per **prefix**: `'dat'` files (the originals) live under
`assets/`, all converted derivatives (`pdf`, `txt`, diagrams…) under `converted/`. Adapters are memoized;
`Seek::Storage.validate_config!` runs in an initializer so misconfiguration **fails at boot**.

**The `full_path` → `nil` contract is the single "is this remote?" signal** the whole codebase relies on.

### 2.2 ContentBlob is the only integration point
Nothing else talks to the adapter directly. `ContentBlob` (`app/models/content_blob.rb`) derives its
key from the existing `uuid` (`storage_key → "<uuid>.dat"`) — **so there is no DB schema change**, and
exposes:
- `storage_adapter(format)` / `storage_key(format)` — the adapter + key for this blob.
- `file_exists?`, `file_size`, `read`/`close`/`rewind` (delegated to an adapter-opened IO) — all backend-agnostic.
- `with_temporary_copy { \|path\| … }` and `make_temp_copy` — see §2.5.

### 2.3 Upload (write) path
Upload is unchanged at the call site — controllers still set `@data` or `tmp_io_object` on the blob and `save`:

1. `before_save :dump_data_to_file` → `dump_data_object_to_file` (`storage_adapter.write`) or
   `dump_tmp_io_object_to_file` (`storage_adapter.copy_from_path` for a real tempfile, else `write`).
2. `before_save :calculate_file_size` reads the size **back from the adapter** (`storage_adapter.size`).
3. Synchronous content inspection (mime sniffing, format detection) still runs on the bytes during save.

So the bytes stream **through the app to S3** on upload; the rest of the model is untouched.
*(Direct browser→S3 upload is the future optimisation discussed in §6.)*

### 2.4 Download path (`lib/seek/content_blob_common.rb`)
`handle_download` → `serve_blob_file(content_blob)` picks one of three routes off `adapter.full_path(key)`:

- **Local** (`full_path` returns a path) → `send_file` the on-disk file (unchanged legacy behaviour).
- **S3, default** → **302 redirect to a presigned URL** (`S3Adapter#presigned_url`, 5-min expiry). The URL
  carries `response-content-disposition`/`response-content-type` overrides so the browser saves the right
  filename/type instead of the opaque `<uuid>.dat`. The bytes go **browser↔S3 directly** — SEEK is not in the data path.
- **S3, `?stream=1`** → `stream_blob_through_app`: HTTP **200** with the bytes streamed chunk-by-chunk through
  SEEK (`adapter.stream` + `self.response_body = Enumerator.new …`). Used **only** for the COPASI/Morpheus
  desktop links (see §6), which cannot follow the cross-host redirect.

### 2.5 The recurring fix for code that needs a real local file
Many libraries (POI, RightField, archive extractors, SBML/JWS readers) require a filesystem path. The pattern:

```ruby
content_blob.with_temporary_copy do |path|   # local: yields real path; S3: streams a tempfile, auto-deleted
  do_something_with(path)
end
```

`make_temp_copy` branches on `full_path`: if local it `cp`s; if S3 it streams `adapter.open` to a tempfile.
`with_temporary_copy_of_converted(format)` does the same for derivatives. This is the change applied across
the extraction / external-tool / spreadsheet / RightField / compare-versions code paths.

## 3. Done (verified on MinIO + unit/functional tests)

| Capability | What works on S3 now |
|---|---|
| Upload / download | Files upload via the adapter; downloads serve correct filename/content-type (presigned redirect). |
| Content-type & format detection | `check_content` / mime sniffing read via the adapter (fixed COPASI-upload crash + a `check_content` lifecycle bug). |
| Versioning | New asset versions carry content forward correctly (fixed a **silent data-loss** bug). |
| Model extraction & simulation | SBML/JWS species & parameter extraction; COPASI/CFF read from S3. |
| Snapshots / RO-bundles | Create, bundle, read all stream from S3. |
| Archive extraction | All 6 formats (zip/tar/7z/gz/bz2/xz) stream from S3. |
| External tools | Spreadsheet→XML (POI), RightField, model-compare run on temp copies streamed from S3. |
| Avatars & model images | Master image stored in S3 (adapter-backed fleximage) + migration task for legacy images. |
| Dev/seed data | Example-data seeders write through the adapter. |
| Image resize / PDF / text extraction | Derivatives generated from a streamed copy, written back to S3. |
| Desktop sim downloads (COPASI/Morpheus) | served as HTTP 200 (streamed) via a `?stream=1` marker. |
| Migration | `rake seek:storage:copy_local_to_s3` (+ `copy_fleximage_to_s3`), idempotent, dry-run. |

## 4. Fresh audit result (this report)

Swept `app/` + `lib/` for the local-filesystem assumption (`*.filepath`, `File.open/exist?`,
`FileUtils.cp`, `Dir.glob`, `send_file`, `File.binwrite`). **Every remaining hit is in workflow
code** — listed in §5. All non-workflow `send_file` sites are local-cache or generated-temp-file
paths (e.g. help-image resize cache, RO-export temp file), which are adapter-safe. No other gaps found.

## 5. Not done / open

### A. Workflows — the remaining storage work *(deliberately deferred to last; not yet started)*
The only files still assuming a local path. Two parts:

1. **Workflow extraction** — `app/models/concerns/workflow_extraction.rb`, `app/controllers/workflows_controller.rb`
   - Diagram (SVG) and RO-Crate zip are written to / read from `content_blob.filepath(...)` and served by local path (`workflow_extraction.rb:140,303,311`, `workflows_controller.rb:259`).
   - **Task:** store these derivatives via the *converted* adapter (write + existence + serve), mirroring how PDF derivatives already work; serve via the adapter (presigned/`send_file`).
2. **Git conversion** — `lib/git/converter.rb:43`
   - `ROCrate::Reader.unzip_file_to(blob.filepath, …)` reads the source zip by local path.
   - **Task:** wrap the source read in `blob.with_temporary_copy`.

   *Effort: ~2.5–3.5 days. Most complex part of the project (generates **and** serves derivative artifacts). Excluded until now by request; everything else is complete, so it can be tackled in isolation.*
