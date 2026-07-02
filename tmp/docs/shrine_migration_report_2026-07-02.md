# Shrine — Pros/Cons, Future Migration Path, and a Direct-Upload-Only Plan

**Date:** 2026-07-02 · **Context:** `s3-support` branch (see `s3_audit_report_2026-06-29.md`) already ships a
working, tested, config-only S3 backend for `ContentBlob`/`Avatar`/`ModelImage` via a small custom adapter
layer (`Seek::Storage`, `LocalAdapter`/`S3Adapter`). This document evaluates whether to replace that layer
with [Shrine](https://github.com/shrinerb/shrine), and — since direct-to-S3 browser upload has been called
out as essential — proposes using Shrine narrowly for that one problem instead.

## 1. What Shrine is, briefly

Shrine is a mature Ruby file-attachment toolkit: pluggable **storages** (local disk, S3, GCS, …) behind a
common interface, an **uploader** class that defines processing/validation, and an **attachment** module
mixed into a model that manages a `<attachment>_data` JSON/text column (`{id, storage, metadata}`). It ships
a large plugin set — `derivatives`, `presign_endpoint`, `upload_endpoint`, `backgrounding`,
`restore_cached_data`, `determine_mime_type`, etc.

## 2. Pros of a full migration to Shrine

- **Direct-to-S3 upload is a first-class, battle-tested feature** — `presign_endpoint` + Uppy on the client,
  with support for presigned POST/PUT, multipart, and resumable (tus) uploads for very large files.
- **Offloads long-term maintenance** of upload/storage edge cases (retry semantics, content-type sniffing
  after direct upload, multipart thresholds, provider quirks) to an actively maintained gem instead of
  in-house code.
- **`:cache` / `:store` separation** is a clean, idiomatic answer to "the app never saw the bytes" — files
  land in a cache location first, get validated/scanned, and are only promoted (moved/copied) to permanent
  storage on success. `backgrounding` lets promotion happen in a `delayed_job` (which SEEK already uses).
- **Derivatives plugin** models multiple named variants (thumbnails, converted PDF/text) as structured JSON
  entries rather than SEEK's current convention of a parallel `converted/` prefix keyed by format string.
- Broader plugin/storage ecosystem if a future need arises (GCS, Azure, Cloudinary) beyond what a hand-rolled
  adapter would cover.

## 3. Cons of a full migration to Shrine

- **Forces a schema migration on every SEEK installation**, not just ones adopting S3. FAIRDOM-SEEK is
  self-hosted by many institutions (FAIRDOMHub is only the public instance). Shrine manages local-disk
  attachments through the same `<attachment>_data` column as S3 ones, so *every* existing `ContentBlob`,
  `Avatar`, and `ModelImage` row — on every install, S3 or not — needs a backfill migration at upgrade time.
  This is the exact cost the current design's "no DB schema change" property was built to avoid.
- **`ContentBlob` carries a lot of logic that isn't about storage**: URL-based remote content
  (`Seek::DownloadHandling::*Handler`, openBIS/NeLS integration via `prepend`), cross-version asset content,
  RDF generation, checksums (`Seek::Data::Checksums`), search-term extraction, fleximage-based thumbnailing.
  None of this goes away with Shrine — it all has to be re-wired around Shrine's attachment abstraction
  rather than the current direct `storage_adapter`/`storage_key` calls.
- **Re-risks a large amount of already-working, tested code.** This branch's 41 commits touched ~20 call
  sites (versioning, model extraction, snapshot generation, archive extraction, RightField, avatars, COPASI
  simulator, citations/CFF reading) via the `with_temporary_copy` pattern. A Shrine migration would mean
  re-touching most of these again against a different IO/attachment interface, with the attendant regression
  risk, for a codebase where the actual gap (direct upload) is much narrower than "replace the whole layer."
- **Custom behaviour Shrine doesn't give for free**: the dual-mode download (presigned 302 redirect by
  default, HTTP 200 streamed proxy for COPASI/Morpheus desktop apps via `?stream=1`) is bespoke SEEK logic
  that would still need to be hand-built on top of Shrine's `UploadedFile#stream`/`#url` primitives.
- **Local-backend installs currently get a mathematically zero-risk upgrade** — `LocalAdapter#full_path` is
  provably identical to the pre-branch `ContentBlob#filepath` construction (same config paths, same
  `uuid.format` naming), confirmed by diff. Shrine has no equivalent "this is definitely a no-op for local
  storage" property, because it always requires the data column.
- **Team/dependency risk**: another gem's release cadence, plugin API surface, and upgrade path become a
  dependency for a core, high-traffic part of the app (every asset download/upload goes through it).

## 4. Migrating to Shrine *later*, after S3 already has real data

This is the scenario the "hard to migrate later" argument is really about: this branch ships, some
installations turn on `backend: s3`, and months later the team decides to adopt Shrine anyway. Is it
meaningfully harder than doing it now?

**The good news: the physical bytes don't need to move.** Shrine's storage abstraction doesn't mandate any
particular key format — a custom `Shrine::Storage` class can be written whose `#upload`/`#url`/`#open`
methods map directly onto the *existing* `assets/<uuid>.dat` / `converted/<uuid>.<format>` key convention
already in use (essentially a thin wrapper around the existing `S3Adapter`/`LocalAdapter`). That means a
later migration is a **metadata backfill against existing keys**, not a data-copy operation:

1. **Schema migration**: add `content_blob_data`, `avatar_data`, `model_image_data` columns (JSON/text) —
   still has to run on every install, local or S3, same cost as migrating now.
2. **Backfill script**: for every existing row, construct the Shrine JSON
   `{"id":"<uuid>.dat","storage":"store","metadata":{"filename":...,"size":...,"mime_type":...}}` by copying
   values already present in SEEK's own columns (`original_filename`, `file_size`, `content_type`, `md5sum`)
   — no need to re-read or re-hash the actual file content, and no S3 API calls beyond what a sanity-check
   `exist?` pass would do.
3. **Compatibility storage class**: write and test a `Shrine::Storage` implementation that reproduces the
   current key derivation (`"<uuid>.<format>"`) so Shrine's `:store` resolves to the *same objects already
   in the bucket* — avoiding a bulk re-upload of potentially large volumes of scientific data.
4. **Cut over model/controller code** from `storage_adapter`/`storage_key` calls to Shrine's attachment API,
   re-wiring the SEEK-specific logic (§3) around it, and re-testing the same ~20 call sites again.
5. **Dual-write / rollback window**: because this is a live-data cutover (unlike doing it pre-release), it
   would need a period where both code paths can read existing data safely, and a clear rollback plan if the
   backfill or cutover has a defect discovered post-deploy — a burden that doesn't exist if this is decided
   before the branch ships.

**Conclusion**: migrating later is *possible* without moving objects in the bucket, so "impossible" is too
strong. But the schema-migration and code-rewrite costs are the same order of magnitude whether done now or
later — the thing that gets harder later is purely the *live-data cutover risk* (step 5), which is avoidable
by not carrying real production S3 data into the decision at all, i.e. deciding before this branch is widely
deployed. That's a real point in favour of deciding sooner rather than later — but it argues for *deciding
the direct-upload approach now* (§7 below), not for migrating the whole storage layer now.

## 5. Is the metadata we store today the same as what Shrine would store?

Similar in philosophy, different in shape — worth spelling out since it affects how mechanical a "keep the
old columns, sync from Shrine's metadata on save" approach would be, were a full migration ever attempted
(see §3's point on why the existing flat DB columns shouldn't just be dropped).

**Current (verified by reading `lib/seek/storage/s3_adapter.rb`)**: `write`/`copy_from_path` call
`put_object(bucket:, key:, body:)` with **no `content_type:` and no `metadata:` hash**. The S3 object itself
carries no descriptive metadata at all — no real Content-Type, no filename. Everything (`content_type`,
`file_size`, `original_filename`, `md5sum`) lives exclusively in the `content_blobs` SQL columns. The correct
filename/content-type is injected only at download time, as presigned-URL response-header *overrides*
(`response_content_disposition`/`response_content_type`) — a deliberate choice, per the existing code comment
that the object is stored under "an opaque `<uuid>.dat` key."

**Shrine's default**: also treats the object store as dumb bytes and keeps descriptive metadata in the app
database, not as S3 object metadata (`x-amz-meta-*` headers) — confirmed via Shrine's docs. The difference is
*shape*: Shrine serializes a single `Shrine::UploadedFile` JSON blob (`{id, storage, metadata: {filename,
size, mime_type, ...}}`) into the `<attachment>_data` column, rather than SEEK's flat typed columns. The
optional `metadata_attributes` plugin can mirror values back out into separate DB columns — the natural way
a full migration would avoid rewriting every existing read site, by keeping SEEK's current flat columns and
syncing them from Shrine's metadata on save rather than switching every call site over to reading the JSON
blob directly.

**One likely but unconfirmed difference**: Shrine's S3 storage is generally understood to pass the detected
`mime_type` as the real `Content-Type` header on the `put_object` call by default, meaning a Shrine-stored
object would report the correct MIME type if browsed directly in the S3/MinIO console or via a bare URl —
where the current SEEK objects would show a generic/binary type since nothing sets it on write. This wasn't
confirmed against Shrine's actual source (the hosted docs didn't spell it out) and should be checked before
relying on it for a decision; it's a minor point either way since neither approach treats S3 object metadata
as authoritative.

**Bottom line**: a backfill migration populating Shrine's data column for existing rows — whether run on a
clean slate or against an install with real S3 data already in it (§4) — is legitimately a metadata-only
operation in both directions: no S3 API calls are needed to *extract* filename/size/type for existing rows
(they're already in SEEK's own columns), only to *verify* that a key-compatible Shrine storage class resolves
to the right existing object.

## 6. Shrine features not used today that would be hard to add the current way

Assessed against SEEK's domain (large scientific datasets/models, self-hosted at scale, now adding direct
upload):

- ~~Resumable / multipart uploads~~ — **correction**: this was originally listed here as something that
  needs a full migration, but it doesn't. If §7's narrow adoption already exists (the `shrine` gem, a
  `:cache` `Shrine::Storage::S3` instance, an authenticated presign endpoint), multipart/resumable upload is
  a cheap *extension* of it, not a separate project: swap the presign strategy for the multipart-aware one
  (Uppy's `@uppy/aws-s3-multipart` client plugin + Shrine's corresponding multipart presign support) and add
  a `complete_multipart_upload` step to the finalize handler. The genuinely hard, from-scratch version of
  this (hand-implementing S3 multipart orchestration — initiate/upload-part/list-parts/complete — plus
  client-side chunking/retry) is only the comparison point if *not* adopting even the narrow plan. See the
  "Natural extensions" note under §7. This is *not* a reason favouring a full migration.
- **Safe async validation before a direct upload goes live** (virus/malware scanning, content policy checks).
  Once uploads go direct-to-S3, bytes can land in the bucket before SEEK inspects them at all. Shrine's
  cache→store separation exists for exactly this. The narrow-adoption plan in §7 below already stumbles into
  a version of this (its `cache/` prefix + finalize-copy step is a quarantine window), but adding an actual
  scanning step later also means handling the record-updated-while-background-job-still-promoting race —
  which Shrine's `backgrounding`/`atomic_helpers` plugins solve and hand-rolled code would need to reinvent.
- **Storage mirroring / dual-write** (`mirroring` plugin). This branch already had to hand-build a one-shot
  batch migrator (`LocalToS3Migrator`) for local→S3. Any future storage transition (provider change, adding a
  redundant backup store, or a later full Shrine migration's own live-data dual-write window, per §4's point
  about cutover risk) needs the same kind of bespoke script again. Shrine's mirroring plugin makes "write to
  two storages simultaneously" a standing capability instead.

**Explicitly not an advantage either way**: storage-class/lifecycle tiering (e.g. moving old assets to S3
Glacier) sounds like it belongs on this list but isn't gated by the storage framework at all — S3 lifecycle
rules act directly on object keys, transparent to whichever system wrote them.

## 7. Recommended plan: use Shrine *only* for direct-to-S3 upload

Keep `ContentBlob`/`Seek::Storage` exactly as they are today for reads, downloads, versioning, RDF, and all
SEEK-specific logic. Use Shrine narrowly as a well-tested utility for the one genuinely hard sub-problem —
safely getting bytes from a browser straight into S3 — then hand off to the existing, already-tested save
path. No schema change, no rewrite of existing call sites.

### Flow

1. Client requests upload authorization from a SEEK-authenticated endpoint (checks the same
   `can_edit?`/policy rules the current upload controller already enforces).
2. That endpoint uses **Shrine's `presign_endpoint` plugin** internally (or calls the presign logic directly,
   without mounting Shrine's generic Rack endpoint) against a `Shrine::Storage::S3` instance configured with
   the *same bucket/credentials already in `seek_storage.yml`*, under a `cache/` prefix distinct from
   `assets/`/`converted/`.
3. Browser PUTs/POSTs the file **directly to S3** using the presigned params (bytes never touch SEEK).
4. Client calls a small SEEK "finalize" endpoint with the returned `{id, storage, metadata}` JSON.
5. Finalize handler:
   - Server-side `copy_object` from `cache/<shrine-id>` to the canonical `assets/<uuid>.dat` key (S3-to-S3,
     no bytes through the app, cheap) — add this as a new method on the existing `S3Adapter`. **Explicitly
     pass `metadata_directive: 'REPLACE'`** (and no `content_type:`/`metadata:`) on this copy, rather than
     relying on S3's default `COPY` directive. Without this, if Shrine's `:cache` storage set a real
     `Content-Type` on the object when the browser uploaded it (see §5/§6 — unconfirmed but likely default
     Shrine behaviour), that header would carry through to the canonical object by default, while every
     object written via the *existing* server-proxied path (local backend, or non-direct S3 uploads,
     untouched by this plan) still gets none — an inconsistency that should be a deliberate choice, not an
     accident of which upload path a given file happened to take.
   - Deletes the cache object.
   - Runs the **existing, already-tested** `with_temporary_copy` + `check_content` pipeline to do mime
     sniffing / content inspection (unavoidable: the app never saw the bytes at upload time, so this has to
     happen post-upload regardless of framework — see the earlier discussion of `expires_in`/streaming).
     Note this also means the `metadata` in the presign response (client-reported filename/size/MIME type
     from the browser's `File` object, via Uppy) is **not** trustworthy enough to skip this step — it's
     unverified client input, which is exactly why Shrine itself ships `restore_cached_data`/
     `refresh_metadata` plugins for direct uploads. Treat it as a hint for progress UI only, not as the
     source of truth `check_content` already provides.
   - Creates the `ContentBlob` row exactly as the current synchronous-upload path does, just skipping the
     `dump_data_to_file` byte-write step since the object is already in place.
6. On the **local** backend, this whole flow is simply not offered — uploads keep working exactly as today
   (multipart form → `tmp_io_object` → `save`). Direct upload only makes sense when `backend: s3`.

### Why the cache→copy step, instead of presigning straight to the final key

Presigning directly to `assets/<uuid>.dat` would save the copy step, but loses Shrine's idiomatic
cache/validate/promote separation (a natural point to reject or virus-scan an upload before it's treated as
real content) and a natural boundary for cleaning up abandoned uploads via an S3 lifecycle rule on the
`cache/` prefix (e.g. expire objects older than 24h that were never finalized). The copy itself is a
metadata-only S3 operation (no data re-upload), so the cost is negligible.

### Scope / surface area

- New dependency: `shrine` gem (reuses the `aws-sdk-s3` dependency already present).
- New config: a second `Shrine::Storage::S3` instance (`:cache`), reusing existing `seek_storage.yml` S3
  credentials — only instantiated when `backend: s3`.
- New route + controller actions: authorize → presign, and finalize.
- New method on `S3Adapter`: `copy_object(src_key, dest_key)` (or reuse `copy_from_path`-style pattern).
- Client-side: JS to PUT directly to the presigned URL with progress reporting, replacing the multipart file
  input's default browser-upload behaviour on the S3 backend (Uppy is the natural fit given the ecosystem,
  but a plain `XMLHttpRequest`/`fetch` PUT is also sufficient for a single presigned PUT URL).
- S3 lifecycle rule (or a scheduled cleanup job) to expire orphaned `cache/` objects.

This keeps Shrine's footprint to a small, replaceable slice of the upload path — it doesn't touch
`ContentBlob`'s schema, its read path, versioning, RDF, or any of the ~20 already-migrated call sites. If
Shrine ever turned out to be the wrong choice, only this slice would need to be replaced.

### Natural extensions once this exists

Two of the §6 "hard to add ourselves" items become materially cheaper once this narrow plan is in place,
because the prerequisite infrastructure (the `shrine` gem, a `:cache` S3 storage, an authenticated presign
endpoint, Uppy on the client) already exists:

- **Multipart/resumable upload** — swap the single-part presign strategy for the multipart-aware one and add
  a completion step to finalize. Not required for the initial version, but worth designing the presign
  endpoint/finalize handler with this in mind (e.g. don't hard-code single-part assumptions) if large file
  sizes are expected soon.
- **Async validation before promotion** (virus scanning etc.) — the `cache/` → `assets/` copy step is already
  a quarantine boundary; inserting a scan between "finalize received" and "copy to canonical key" is a
  natural addition later, not a redesign.

Storage mirroring (§6) is not made easier by this plan — it's orthogonal, since it concerns writing to two
*permanent* storages, not the temporary cache stage.

### Rough effort estimate

- Presign + authorization endpoint: ~1 day (mostly wiring existing policy checks to a new action).
- `S3Adapter#copy_object` + finalize endpoint + `ContentBlob` creation path: ~1 day.
- Client-side direct-upload JS + progress UI: ~1–1.5 days (existing upload forms need a conditional path).
- Orphan cleanup (lifecycle rule or job) + tests (unit + a system/integration test for the full flow): ~1 day.
- **Total: ~4–5 days**, comparable to or smaller than the workflows gap already scoped in the audit report,
  and with no risk to already-shipped code.

## 8. Summary

| | Full Shrine migration | Shrine for direct-upload only |
|---|---|---|
| Schema change | Yes, on every install | No |
| Re-touches existing tested code | Yes (~20 call sites) | No |
| Solves direct-to-S3 upload | Yes | Yes |
| Solves long-term maintenance of *all* storage code | Yes | No — only the upload leg |
| Risk to already-shipped behaviour | High | Low |
| Effort | Large (comparable to redoing most of this branch) | ~4–5 days |

**Recommendation**: do not migrate to Shrine wholesale. Adopt it narrowly, as a presign/direct-upload utility
sitting in front of the existing `Seek::Storage` layer, per §7. Revisit a full migration only if a concrete
need emerges that the narrow adoption can't satisfy (e.g. wanting Shrine's `derivatives` plugin for
converted-file management) — and if so, §4 shows that decision doesn't get meaningfully harder by waiting,
provided it's made before large volumes of production S3 data accumulate.
