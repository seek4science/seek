# RO-Crate in WorkflowHub (FAIRDOM-SEEK)

This document summarises how this codebase, which runs [WorkflowHub](https://workflowhub.eu/) as well as
[FAIRDOMHub](https://fairdomhub.org/), uses and supports [RO-Crate](https://www.researchobject.org/ro-crate/).

In short: RO-Crate support is **almost entirely about Workflows**. A [Workflow RO-Crate](https://w3id.org/workflowhub/workflow-ro-crate/)
is the main way a workflow comes in and goes out, and the main way it is stored and exchanged. No other asset
type (DataFile, Sop, Model, Investigation and so on) gets an RO-Crate.

## Specifications, profiles and software referenced

| What | Link | Where used |
|---|---|---|
| RO-Crate specification | <https://w3id.org/ro/crate> ([1.3](https://w3id.org/ro/crate/1.3), the gem's default; reads 1.0 to 1.3) | base `conformsTo`, via [`ROCrate::Metadata::SPEC`](https://github.com/ResearchObject/ro-crate-ruby/blob/v0.7.0/lib/ro_crate/model/metadata.rb#L9-L13) of the gem |
| Workflow RO-Crate profile 1.0 | <https://w3id.org/workflowhub/workflow-ro-crate/1.0> | [`workflow_crate.rb#L5`](../lib/overrides/ro_crate/workflow_crate.rb#L5) |
| Workflow Testing RO-Crate | <https://lifemonitor.eu/workflow_testing_ro_crate> | `TestSuite` detection, [`workflow_crate.rb#L52`](../lib/overrides/ro_crate/workflow_crate.rb#L52) |
| Bioschemas ComputationalWorkflow 1.0-RELEASE | <https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/> | [`bio_schema/resource_decorators/workflow.rb#L6`](../lib/seek/bio_schema/resource_decorators/workflow.rb#L6) |
| Bioschemas FormalParameter 1.0-RELEASE | <https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/> | [`bio_schema/resource_decorators/workflow.rb#L8`](../lib/seek/bio_schema/resource_decorators/workflow.rb#L8) |
| FAIR Signposting | <https://signposting.org/FAIR/> | [`fair_signposting.rb`](../app/controllers/concerns/fair_signposting.rb) |
| GA4GH Tool Registry Service (TRS) v2 | <https://ga4gh.github.io/tool-registry-service-schemas/> | [`app/controllers/ga4gh/trs/v2/`](../app/controllers/ga4gh/trs/v2/) |
| Citation File Format (CFF) | <https://citation-file-format.github.io/> | [`workflow_extractors/cff.rb`](../lib/seek/workflow_extractors/cff.rb) |
| Common Workflow Language (abstract CWL) | <https://www.commonwl.org/> | [`workflow_extractors/cwl.rb`](../lib/seek/workflow_extractors/cwl.rb) |
| `ro-crate` Ruby gem, version 0.7.0 | <https://github.com/ResearchObject/ro-crate-ruby>, <https://rubygems.org/gems/ro-crate> | [`Gemfile#L94`](../Gemfile#L94) |
| `licensee` gem | <https://github.com/licensee/licensee> | [`ro_crate_project.rb`](../lib/licensee/projects/ro_crate_project.rb) |
| `json-ld` gem | <https://github.com/ruby-rdf/json-ld> | Bioschemas flattening in [`workflow_extraction.rb#L178`](../app/models/concerns/workflow_extraction.rb#L178) |
| LifeMonitor | <https://lifemonitor.eu/> | [`lib/life_monitor/`](../lib/life_monitor/), [`life_monitor_submission_job.rb`](../app/jobs/life_monitor_submission_job.rb) |
| Galaxy (TRS import, "Run" button) | <https://galaxyproject.org/> | [`workflow_extraction.rb`](../app/models/concerns/workflow_extraction.rb) `run_url` |
| RO-Bundle (older format, used for ISA snapshots) | <https://w3id.org/bundle/> | [`research_objects/generator.rb`](../lib/seek/research_objects/generator.rb) |

## 1. Foundation

SEEK builds on the [`ro-crate`](https://github.com/ResearchObject/ro-crate-ruby) gem and adds its own subclasses in
[`lib/overrides/ro_crate/`](../lib/overrides/ro_crate/):

| Class | Role |
|---|---|
| [`ROCrate::WorkflowCrate`](../lib/overrides/ro_crate/workflow_crate.rb) | Adds [`https://w3id.org/workflowhub/workflow-ro-crate/1.0`](https://w3id.org/workflowhub/workflow-ro-crate/1.0) to `conformsTo` ([L15-L21](../lib/overrides/ro_crate/workflow_crate.rb#L15-L21)). Requires a `mainEntity`. Provides `main_workflow`, `main_workflow_diagram` (`image`), `main_workflow_cwl` (`subjectOf`), `test_suites` (`TestSuite` entities found via `mentions`/`about`, [L52](../lib/overrides/ro_crate/workflow_crate.rb#L52)) and `source_url` (taken from the crate's `@id`, `isBasedOn`, `url`, or the main workflow's `url`, [L60](../lib/overrides/ro_crate/workflow_crate.rb#L60)). |
| [`ROCrate::Workflow`](../lib/overrides/ro_crate/workflow.rb) | Typed as `File`, `SoftwareSourceCode` and `ComputationalWorkflow`, with `programmingLanguage`, `image` and `subjectOf`. |
| [`ROCrate::WorkflowDiagram`](../lib/overrides/ro_crate/workflow_diagram.rb) | Typed as `File` and `ImageObject`. |
| [`ROCrate::WorkflowDescription`](../lib/overrides/ro_crate/workflow_description.rb) | The abstract CWL. Typed as `File`, `SoftwareSourceCode` and `HowTo`, with `programmingLanguage` set to CWL. |
| [`ROCrate::WorkflowCrateReader`](../lib/overrides/ro_crate/workflow_crate_reader.rb) | Reads a crate and marks out the main workflow, diagram and CWL entities (`mainEntity` → `image` / `subjectOf`). |

[`config/application.rb`](../config/application.rb) and [`config/initializers/inflections.rb`](../config/initializers/inflections.rb)
contain loading and naming fixes for these classes.

**Detection.** A workflow counts as a crate if its uploaded file name ends in `.crate.zip`, or if its git version
contains `ro-crate-metadata.json` or `ro-crate-metadata.jsonld`
([`git/version.rb#L149`](../app/models/git/version.rb#L149),
[`workflow_extraction.rb#L30-L44`](../app/models/concerns/workflow_extraction.rb#L30-L44)). A file ending in
`.basic.crate.zip` is treated as a crate whose metadata should be regenerated.

## 2. Getting crates in (import)

| Route | Code |
|---|---|
| Web UI: upload a crate zip or give a URL (`create_from_ro_crate`, `create_version_from_ro_crate`) | [`workflows_controller.rb#L97`](../app/controllers/workflows_controller.rb#L97), [`#L147`](../app/controllers/workflows_controller.rb#L147), [`workflow_crate_extractor.rb`](../app/forms/workflow_crate_extractor.rb) |
| JSON API: `POST /workflows` with an `ro_crate` parameter, or a new version | [`handle_ro_crate_api_post`](../app/controllers/workflows_controller.rb#L353) |
| `POST /workflows/submit`: matches an existing workflow by the crate's `source_url` and its `version`, then either adds a new version or does nothing if that version already exists. Meant for CI tools such as GitHub Actions. | [`workflows_controller.rb#L326`](../app/controllers/workflows_controller.rb#L326), [`find_workflows_matching_id`](../app/forms/workflow_crate_extractor.rb#L80) |
| Build a workflow from loose files (main workflow, diagram, CWL); it is later served as a crate | [`create_from_files`](../app/controllers/workflows_controller.rb#L112), [`workflow_repository_builder.rb`](../app/forms/workflow_repository_builder.rb); legacy: [`legacy/workflow_crate_builder.rb`](../app/models/legacy/workflow_crate_builder.rb) |
| Converting an older blob-based workflow to git | [`lib/git/converter.rb#L91`](../lib/git/converter.rb#L91) unzips the crate into a git repo and sets git annotations from `mainEntity`, `image` and `subjectOf` |
| GitHub scraper | [`lib/scrapers/github_scraper.rb`](../lib/scrapers/github_scraper.rb) |

Routes are defined in [`config/routes.rb#L568-L587`](../config/routes.rb#L568-L587).

On import, the crate is **unpacked into a git repository**
([`WorkflowCrateExtractor#build`](../app/forms/workflow_crate_extractor.rb#L15)). The paths of the main workflow,
diagram and abstract CWL are recorded as git annotations, and the crate's `version` becomes the git version name.

## 3. Reading metadata from a crate

[`Seek::WorkflowExtractors::ROCrate`](../lib/seek/workflow_extractors/rocrate.rb) builds on
[`ROLike`](../lib/seek/workflow_extractors/rolike.rb).

- **From the crate's root entity** ([`metadata_from_crate`](../lib/seek/workflow_extractors/rocrate.rb#L78)):
  - `name` → title
  - `description` → description
  - `keywords` → tags
  - `license` → licence, normalised with `Seek::License.normalize`
  - `author` and `creator` → SEEK creators. Entries typed `Person` become creators; other entities
    (organisations, for example) go into `other_creators`.
  - `source_url` → source link, which triggers extra metadata extraction through the remote content handler
    (GitHub, for example)
- **The workflow type** (Galaxy, CWL, Nextflow and so on) comes from the main workflow's `programmingLanguage`,
  matched by [`WorkflowClass.match_from_metadata`](../app/models/workflow_class.rb)
  ([`rocrate.rb#L157`](../lib/seek/workflow_extractors/rocrate.rb#L157)).
- **The main workflow is parsed by its language-specific extractor** in
  [`lib/seek/workflow_extractors/`](../lib/seek/workflow_extractors/). If the crate has an abstract CWL, that is used for
  inputs, outputs and steps instead.
- **Fallbacks inside the crate:** `README.md` supplies the description
  ([`rolike.rb#L73`](../lib/seek/workflow_extractors/rolike.rb#L73)), `CITATION.cff` is read through the
  [CFF extractor](../lib/seek/workflow_extractors/cff.rb), and the licence file is detected with
  [licensee](https://github.com/licensee/licensee) ([`ro_crate_project.rb`](../lib/licensee/projects/ro_crate_project.rb)).
- **Diagram:** an `image` in the crate is used if present; otherwise one is generated from the workflow or the CWL.
- **Tests:** [`has_tests?`](../lib/seek/workflow_extractors/rocrate.rb#L7) is true when the crate has a `TestSuite`
  ([Workflow Testing RO-Crate](https://lifemonitor.eu/workflow_testing_ro_crate)). This is what the
  [LifeMonitor](https://lifemonitor.eu/) integration relies on.

## 4. Generating crates (export)

[`WorkflowExtraction#ro_crate`](../app/models/concerns/workflow_extraction.rb#L213) and
[`#populate_ro_crate`](../app/models/concerns/workflow_extraction.rb#L108):

- **If a full crate was uploaded, it is passed through as it is.** SEEK only builds new metadata for non-crate
  uploads and `.basic.crate.zip` uploads ([`should_generate_crate?`](../app/models/concerns/workflow_extraction.rb#L42)).
- **When it does build one:**
  - The main workflow, diagram and CWL entities are created from git blobs
    ([`Git::Blob#to_crate_entity`](../app/models/git/blob.rb#L77)), with a `contentUrl` pointing to `git_download`.
    Remote files become external `File` entities with a `localPath`.
  - `programmingLanguage` is a `ComputerLanguage` entity
    ([`WorkflowClass#ro_crate_metadata`](../app/models/workflow_class.rb#L35)).
  - Authors are `Person` entities whose `@id` is the person's [ORCID](https://orcid.org/) where available,
    otherwise `#person-N` ([`Person#ro_crate_metadata`](../app/models/person.rb#L364)). Text-only creators become
    `#creator-N`. Projects have [`Project#ro_crate_metadata`](../app/models/project.rb#L278).
  - `license` is the licence URL. `identifier` is the DOI if there is one, otherwise the SEEK URL. `url`,
    `datePublished`, `sdDatePublished` and `isBasedOn` are set, and `creativeWorkStatus` comes from the maturity
    level.
  - **The [Bioschemas](https://bioschemas.org/) JSON-LD is merged in**
    ([`merge_entities`](../app/models/concerns/workflow_extraction.rb#L178)): the workflow's
    [ComputationalWorkflow](https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/) /
    [FormalParameter](https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/) output from
    [`bio_schema/resource_decorators/workflow.rb`](../lib/seek/bio_schema/resource_decorators/workflow.rb) is flattened,
    its fields are copied onto the main workflow entity, and its other nodes are added as contextual entities.
  - An HTML preview (`ro-crate-preview.html`) is rendered from [`script/preview.html.erb`](../script/preview.html.erb).
- **Zips are cached** under the filestore: `git_version_<id>.crate.zip`, or the content blob's `crate.zip`
  ([`ro_crate_path`](../app/models/concerns/workflow_extraction.rb#L324)), written by
  [`ro_crate_zip`](../app/models/concerns/workflow_extraction.rb#L245).

## 5. Where crates are served

- `GET /workflows/:id/ro_crate?version=N` returns the zip, named `workflow-<id>-<ver>.crate.zip`
  ([`workflows_controller.rb#L272`](../app/controllers/workflows_controller.rb#L272),
  [`ro_crate_handling.rb`](../app/controllers/concerns/ro_crate_handling.rb)). The ordinary
  [`download`](../app/controllers/workflows_controller.rb#L268) action for workflows also returns the crate.
- `GET /workflows/:id/ro_crate_metadata` returns just the `ro-crate-metadata.json`
  ([`#L277`](../app/controllers/workflows_controller.rb#L277)).
- Both routes are available through the [JSON API](../public/api/index.html) (`api_actions`) and follow download
  permissions ([`permissions/translator.rb#L15`](../lib/seek/permissions/translator.rb#L15),
  [`application_controller.rb#L412`](../app/controllers/application_controller.rb#L412)).
- **[FAIR Signposting](https://signposting.org/FAIR/):** landing pages send an HTTP `Link` header with
  `rel="item"`, `profile="https://w3id.org/ro/crate"` that points to the crate zip
  ([`fair_signposting.rb#L28`](../app/controllers/concerns/fair_signposting.rb#L28)).
- **[GA4GH TRS v2](https://ga4gh.github.io/tool-registry-service-schemas/)** works directly from the crate
  ([`tool_versions_controller.rb`](../app/controllers/ga4gh/trs/v2/tool_versions_controller.rb),
  [`file_wrapper.rb`](../app/models/ga4gh/trs/v2/file_wrapper.rb),
  [`tool_version.rb`](../app/models/ga4gh/trs/v2/tool_version.rb)):
  - [`descriptor`](../app/controllers/ga4gh/trs/v2/tool_versions_controller.rb#L20) returns the main workflow, or the
    file at `relative_path` inside the crate.
  - [`files`](../app/controllers/ga4gh/trs/v2/tool_versions_controller.rb#L56) lists the crate's entries, and with
    `?format=zip` returns the crate zip.
  - [`tests`](../app/controllers/ga4gh/trs/v2/tool_versions_controller.rb#L46) returns the files matching `test/*.json`.
  - [`containerfile`](../app/controllers/ga4gh/trs/v2/tool_versions_controller.rb#L64) returns the crate's `Dockerfile`.
  - [Galaxy](https://galaxyproject.org/)'s "Run" button imports workflows through this TRS URL.
- **UI:** a "Download RO-Crate" button
  ([`_asset_buttons.html.erb#L41`](../app/views/assets/_asset_buttons.html.erb#L41)).

## 6. Tests

There are 24 crate fixtures in [`test/fixtures/files/workflows/`](../test/fixtures/files/workflows/), covering:

- crates with an `@id` but no version, and with numeric IDs
- different licence forms
- authors versus creators, and creators with ORCIDs
- CFF files
- test suites
- entirely remote files
- missing files and a missing main workflow
- [nf-core](https://nf-co.re/) and [COMPSs](https://compss.bsc.es/) crates
- file names with spaces and dots

## WorkflowHub versus other SEEK deployments

The same code base runs [WorkflowHub](https://workflowhub.eu/), [FAIRDOMHub](https://fairdomhub.org/) and other
SEEK instances (see the [README](../README.md)). Nothing in the code checks whether it is running as WorkflowHub; all
RO-Crate behaviour is switched on by ordinary settings in `Seek::Config`. They are set in the admin UI
([`features_enabled.html.erb`](../app/views/admin/features_enabled.html.erb)) and declared in
[`config_setting_attributes.yml`](../lib/seek/config_setting_attributes.yml).

| Setting | Default in [`seek_configuration.rb`](../config/initializers/seek_configuration.rb) | Effect on RO-Crate |
|---|---|---|
| `workflows_enabled` | `false` ([L97](../config/initializers/seek_configuration.rb#L97)) | Without it there are no Workflows, so no crate import or export at all ([`workflows_controller.rb#L7`](../app/controllers/workflows_controller.rb#L7)). |
| `git_support_enabled` | `false` ([L275](../config/initializers/seek_configuration.rb#L275)) | On: crates are unpacked into git repositories (sections 2 to 4). Off: the **legacy** path stores the uploaded `.crate.zip` as a plain content blob ([`legacy_handle_ro_crate_api_post`](../app/controllers/concerns/legacy/workflow_support.rb#L70)), and loose files are packed into a crate by [`Legacy::WorkflowCrateBuilder`](../app/models/legacy/workflow_crate_builder.rb). |
| `ga4gh_trs_api_enabled` | not set (off) | The TRS API, which serves files out of the crate, returns 404 when off ([`trs_base_controller.rb#L39`](../app/controllers/ga4gh/trs/v2/trs_base_controller.rb#L39)). Galaxy's "Run" button depends on it. |
| `fair_signposting_enabled` | not set (off) | Off: no `Link` headers, so the crate can't be found by Signposting ([`assets_common.rb#L13`](../lib/seek/assets_common.rb#L13)). On: every asset gets Signposting links, but only Workflows get the RO-Crate `item` link. |
| `life_monitor_enabled` | `false` ([L272](../config/initializers/seek_configuration.rb#L272)) | Sends workflows with test suites (Workflow Testing RO-Crate) to [LifeMonitor](https://lifemonitor.eu/). |
| `galaxy_instance_default` | — | Galaxy server used by the "Run" button (TRS import). |

The test environment switches TRS and Signposting on
([`seek_testing.rb#L149-L155`](../config/initializers/seek_testing.rb#L149-L155)).

What this means in practice:

- **WorkflowHub** has all of the above switched on and is effectively the only deployment that uses RO-Crate.
- **A default SEEK install** (FAIRDOMHub-style, ISA-centred) has workflows switched off and produces no RO-Crates.
  Its export format for ISA structures is the RO-Bundle snapshot. A SEEK instance that enables workflows without
  git support gets the legacy path, which has fewer features.
- **Wording and links in the UI are WorkflowHub-specific even on other instances.** The workflow upload pages link to
  WorkflowHub's documentation ([`workflows/new.html.erb#L21`](../app/views/workflows/new.html.erb#L21)). Several
  forms still link to the old wiki page `github.com/workflowhub-eu/about/wiki/Workflow-RO-Crate`
  ([`_upload_form.html.erb#L121`](../app/views/workflows/_upload_form.html.erb#L121),
  [`new_git_version.html.erb#L83`](../app/views/workflows/new_git_version.html.erb#L83),
  [`_legacy_upload_form.html.erb#L92`](../app/views/workflows/_legacy_upload_form.html.erb#L92),
  [`new.html.erb#L34`](../app/views/workflows/new.html.erb#L34)) instead of
  <https://about.workflowhub.eu/Workflow-RO-Crate/>.

## Related documentation elsewhere

This file is a map of the code for developers. User and administrator documentation lives in other repositories:

- **[about.workflowhub.eu](https://about.workflowhub.eu/)** ([workflowhub-eu/about](https://github.com/workflowhub-eu/about)):
  the [Workflow RO-Crate profile](https://about.workflowhub.eu/Workflow-RO-Crate/) (currently 1.1, see the
  observations below), and developer pages for the
  [RO-Crate submission API](https://about.workflowhub.eu/developer/ro-crate-api/),
  [how to make a Workflow RO-Crate](https://about.workflowhub.eu/developer/how-to-make-a-workflow-ro-crate/),
  [FAIR Signposting](https://about.workflowhub.eu/developer/signposting/),
  [TRS](https://about.workflowhub.eu/developer/trs/) and
  [Bioschemas](https://about.workflowhub.eu/developer/bioschemas/).
- **[docs.seek4science.org](https://docs.seek4science.org/)**
  ([seek4science/seek-documentation](https://github.com/seek4science/seek-documentation)): SEEK user help
  (`help/`) and installation and administration guides (`tech/`). It doesn't currently cover workflows or RO-Crate.
- **The [JSON API documentation](../public/api/index.html)** in this repository (`public/api/`), served at `/api`.

Unmerged proof-of-concept work on the `schema-knowledge-graph-messing` branch (`docs/schema-kg-work.md`) adds
RO-Crate 1.1, 1.2 and 1.3 JSON-LD contexts for RDF generation, sends each Workflow's RO-Crate metadata to the triple
store, and makes [`open_crate`](../lib/seek/workflow_extractors/rocrate.rb) also yield the crate's root directory.
This document describes `main`.

## Observations and gaps

- **Generated crates mix spec and profile versions.** The base `conformsTo` comes from
  [`ROCrate::Metadata::SPEC`](https://github.com/ResearchObject/ro-crate-ruby/blob/v0.7.0/lib/ro_crate/model/metadata.rb#L9-L13)
  in gem 0.7.0, which defaults to [RO-Crate 1.3](https://w3id.org/ro/crate/1.3).
  [`WorkflowCrate`](../lib/overrides/ro_crate/workflow_crate.rb#L5) then adds
  [Workflow RO-Crate 1.0](https://w3id.org/workflowhub/workflow-ro-crate/1.0), which is a profile of RO-Crate 1.1.
  The [Workflow RO-Crate profile page](https://about.workflowhub.eu/Workflow-RO-Crate/) now redirects to
  [version 1.1](https://about.workflowhub.eu/Workflow-RO-Crate/1.1/), so the declared profile is out of date as
  well. When an uploaded crate is passed through, it keeps whatever versions it declared.
- **Only WorkflowHub-style deployments produce crates.** Workflows, git support, TRS and FAIR Signposting are all
  off by default (see [WorkflowHub versus other SEEK deployments](#workflowhub-versus-other-seek-deployments)), so
  another SEEK instance has no RO-Crate output and no machine-findable crates unless an administrator turns these
  on. Instances without git support get the legacy path, which keeps the uploaded zip as it is.
- **The UI links to an out-of-date description of the format.** Four workflow upload views link to the old wiki
  page `github.com/workflowhub-eu/about/wiki/Workflow-RO-Crate`, and still describe Workflow RO-Crate as "under
  development".
- **The RO-Crate endpoints are missing from the API reference.** The OpenAPI definition in
  [`public/api/definitions/_paths.yml`](../public/api/definitions/_paths.yml) does not mention
  `GET /workflows/{id}/ro_crate`, `GET /workflows/{id}/ro_crate_metadata`, `POST /workflows/submit`, or the
  `ro_crate` parameter of `POST /workflows` and `POST /workflows/{id}/create_version`. The submission API is
  documented only on [about.workflowhub.eu](https://about.workflowhub.eu/developer/ro-crate-api/), and `submit` is not documented on
  either site.
- **Workflows and RO-Crate are not covered in the SEEK documentation.**
  [docs.seek4science.org](https://docs.seek4science.org/) has no page on enabling or administering these features;
  the only documentation is WorkflowHub's own site.
- **[Workflow Run Crates](https://www.researchobject.org/workflow-run-crate/) (Process, Workflow and Provenance Run
  Crate) are not recognised.** They are stored and passed through like any other file, but nothing interprets
  `CreateAction` entities.
- **"RO-Crate snapshots" is a misnomer.** [`CLAUDE.md`](../CLAUDE.md) uses that phrase, but snapshots of
  Investigations, Studies and Assays ([`lib/seek/research_objects/`](../lib/seek/research_objects/)) are older
  [RO-Bundle](https://w3id.org/bundle/) zips (`.ro.zip`, `ROBundle::File`), not RO-Crates. ISA objects and
  DataFiles have no RO-Crate export.
- **Uploaded crates are not rewritten.** WorkflowHub's own metadata (DOI, SEEK creators, licence edits) does not
  appear in them, so the downloaded crate can differ from what the landing page shows.
- **The Bioschemas merge uses a placeholder vocabulary.** It sets `'@vocab' => 'https://somewhere.com/'` as a
  temporary JSON-LD context ([`workflow_extraction.rb#L182`](../app/models/concerns/workflow_extraction.rb#L182)), so
  any term that isn't mapped would end up under that dummy namespace.
- **Crates are only lightly checked.** The only checks on upload are that the crate can be read, that it has a main
  workflow, and (for `submit`) that it has a source URL and version
  ([`workflow_crate_extractor.rb#L75`](../app/forms/workflow_crate_extractor.rb#L75)). No RO-Crate or profile
  validator (such as [rocrate-validator](https://github.com/crs4/rocrate-validator)) is run.
