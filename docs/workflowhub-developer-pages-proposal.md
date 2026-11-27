# Proposed updates to about.workflowhub.eu `developer/` pages

Draft for a later PR to the WorkflowHub site; kept here for review alongside [`ro-crate.md`](ro-crate.md).

Target repository: [workflowhub-eu/about](https://github.com/workflowhub-eu/about), folder `developer/`.
Rule followed: describe observable behaviour (URLs, parameters, file names, what ends up in the crate), never SEEK
class names, source paths or settings. Everything below was checked against seek4science/seek `main` (v1.19 era).

## `developer/ro-crate-api.md` (RO-Crate Submission API): largest gap

Currently: only `POST /workflows` and `POST /workflows/{id}/create_version` with `ro_crate` + `workflow[project_ids][]`.

Add:

1. **`POST /workflows/submit`**: the "smart" endpoint for CI pipelines. Same parameters as `POST /workflows`.
   WorkflowHub finds an existing workflow by the crate's source URL (the root `@id` if it is an `http(s)` URL,
   otherwise `isBasedOn`, otherwise `url`, otherwise the main workflow's `url`) and uses the crate's `version`:
   - no matching workflow → a new workflow is created;
   - one match, new `version` → a new version is added;
   - one match, `version` already registered → nothing changes, the existing workflow is returned;
   - errors if the source URL or `version` is missing, or more than one workflow matches.
2. **Downloading crates**: `GET /workflows/{id}/ro_crate?version=N` (zip, `workflow-{id}-{N}.crate.zip`) and
   `GET /workflows/{id}/ro_crate_metadata?version=N` (just `ro-crate-metadata.json`). Both follow the workflow's
   download permission, and work with an API token for private workflows.
3. **What WorkflowHub reads from your crate** (so submitters know what to put in it):
   - root `name`, `description`, `keywords` (array or comma-separated), `license`, `author`/`creator`
     (`Person` entities become linked creators, ORCID `@id`s are recognised; organisations become "other creators");
   - `version` → version name;
   - main workflow = `mainEntity`; its `programmingLanguage` decides the workflow type;
   - diagram = main workflow's `image`; abstract CWL = main workflow's `subjectOf`;
   - test suites (`TestSuite` via `mentions`/`about`, the Workflow Testing RO-Crate profile) mark the workflow as
     having tests;
   - fallbacks from files in the crate: `README.md` (description), `CITATION.cff`, a `LICENSE` file.
4. **What happens to your crate**: an uploaded crate is kept as uploaded and is what people download. Metadata you
   later edit on WorkflowHub (title, creators, licence, DOI) is *not* written back into it. A crate named
   `*.basic.crate.zip` is treated as files only: WorkflowHub regenerates `ro-crate-metadata.json` and the preview.
   *Check before publishing:* the unmerged `schema-knowledge-graph-messing` branch adds a setting
   `regenerate_workflow_ro_crates` (default on) that writes WorkflowHub's metadata into uploaded crates, so this
   point would change if that branch is merged.
5. A short **error table**: "did not specify a main workflow", "could not be extracted" (not a valid zip),
   "source URL could not be determined" / "version could not be determined" (`submit` only).

## `developer/how-to-make-a-workflow-ro-crate.md`: outdated

- Section 2 says "We are working on a python package": ro-crate-py has been stable for years. Also point to
  the `rocrate` CLI, Galaxy's and nf-core's crate export, and validation with
  [rocrate-validator](https://github.com/crs4/rocrate-validator) (which has a Workflow RO-Crate profile).
- The list of what a generated crate contains should add: `conformsTo` (RO-Crate spec + Workflow RO-Crate profile),
  `identifier` (DOI if minted), `creativeWorkStatus` from the maturity level, `sdDatePublished`, and that all files
  of a git-backed workflow are included, with remote files as external entities.
- Link "BioSchemas workflow profile" to
  <https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/> (current link is the old draft name).
- Add the minimum a crate needs to be accepted: valid zip, `ro-crate-metadata.json`, `mainEntity` pointing to a
  `ComputationalWorkflow`; for `submit` also a source URL and `version`.

## `Workflow-RO-Crate/1.1/` appendix "Extracted Metadata": incomplete

- It lists `name`, `description`, `author`, `license` and `keywords`. WorkflowHub also reads `creator` (alongside
  `author`, with `Person` entities becoming linked creators and others becoming "other creators"), `version` (used as
  the version name, and required by `submit`), the source URL (root `@id` if it is a web URL, else `isBasedOn`,
  `url` or the main workflow's `url`), the main workflow's `programmingLanguage` (to pick the workflow type), and
  whether the crate has a test suite.
- It says the properties are read "from the Crate entity (`./`)". The root may also have an absolute `@id`, as all
  Galaxy Training Network crates do; this works and could be mentioned.
- Fallbacks: also `CITATION.cff` and a licence file in the crate, besides `README.md`.

## `developer/bioschemas.md`: version statement is stale

- "the latest version being 1.0.1 released in November 2021": the profile page now points to Workflow RO-Crate
  **1.1**. Update once WorkflowHub itself declares 1.1 (see below), or state what WorkflowHub currently declares.

## `developer/signposting.md`: mostly fine

- Example is accurate (`rel="item"`, `type="application/zip"`, `profile="https://w3id.org/ro/crate"`).
- Could add that `ro_crate_metadata` is the metadata-only alternative, and that the zip is versioned via
  `?version=`.

## `developer/trs.md`: add how TRS maps onto the crate

- `GET .../versions/{v}/{type}/descriptor` returns the crate's main workflow; `.../descriptor/{relative_path}`
  any file in the crate.
- `.../files?format=zip` returns the full RO-Crate zip.
- `.../tests` lists `test/*.json` / `tests/*.json` files in the crate.
- `.../containerfile` returns a top-level `Dockerfile` if the crate has one.
- Galaxy's "Run on Galaxy" uses TRS import.

## `developer/index.md`

- Add a line for `submit` and for crate download endpoints.
- Mention that the WorkflowHub API reference (`/api`) does not list the RO-Crate endpoints, so the RO-Crate API
  page is the reference.

## Version mismatch: decide before documenting

Crates *generated* by WorkflowHub currently declare RO-Crate **1.3** (default of the ro-crate Ruby gem 0.7.0)
together with Workflow RO-Crate **1.0** (a profile of RO-Crate 1.1). The `Workflow-RO-Crate/` page already defaults
to profile 1.1. Better to fix this in SEEK (declare Workflow RO-Crate 1.1, or pin the spec version the profile is
based on) than to document the mismatch. Until then, `how-to-make` and `bioschemas` should say WorkflowHub accepts
crates of any RO-Crate version 1.0–1.3.

## Not for the developer pages

- SEEK feature switches (workflows, git support, TRS, Signposting, LifeMonitor) are about *other* SEEK
  deployments: these belong in seek-documentation `tech/`, not on WorkflowHub's site.
- Internal details (git storage of crates, Bioschemas merge, cache locations) stay in SEEK's `docs/ro-crate.md`.
