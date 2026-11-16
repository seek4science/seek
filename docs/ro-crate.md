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

This document describes `main`. Unmerged experimental work that changes RO-Crate handling is described in
[Experimental and future work](#experimental-and-future-work).

## RO-Crate alongside SEEK's other linked data

RO-Crate is one of three linked-data outputs in SEEK, and the newest. The other two cover far more of SEEK, but not
Workflows in the same way.

| Output | Vocabulary | Types covered | How it is served |
|---|---|---|---|
| **JERM RDF** (since 2012) | [JERM ontology](http://jermontology.org/ontology/JERMOntology#), Dublin Core, FOAF, SIOC | The types in [`JERMVocab.defined_types`](../lib/seek/rdf/jerm_vocab.rb#L25): Assay, DataFile, Model, Sop, Person, ObservationUnit (as [PPEO](http://purl.org/ppeo/PPEO.owl#observation_unit)), Organism, Project, Programme, Study and others in the ISA family. **Workflow is not one of them.** | `.rdf` on each item page; FAIR Signposting `describedby` with type RDF ([`fair_signposting.rb#L22`](../app/controllers/concerns/fair_signposting.rb#L22)); a Virtuoso triple store ([`virtuoso_repository.rb`](../lib/seek/rdf/virtuoso_repository.rb)) with a SPARQL page ([`sparql_controller.rb`](../app/controllers/sparql_controller.rb), added 2025) and example queries ([`config/sparql_queries.yml`](../config/sparql_queries.yml), 45 uses of `jerm:`) |
| **Schema.org / Bioschemas JSON-LD** | [Schema.org](https://schema.org/), [Bioschemas](https://bioschemas.org/) profiles | Most public types, including Workflow | `<script>` block in each page, `.jsonld`, Signposting `describedby` with type JSON-LD, data dumps |
| **RO-Crate** (since 2019) | RO-Crate (Schema.org based) | Workflows only | See section 5 |

The JERM RDF is produced from a CSV mapping table, [`rdf_mappings.csv`](../lib/seek/rdf/rdf_mappings.csv) (about 80
rows mapping model methods to predicates), by [`rdf_generation.rb`](../lib/seek/rdf/rdf_generation.rb) and
[`csv_mappings_handling.rb`](../lib/seek/rdf/csv_mappings_handling.rb), and kept up to date in the triple store by
background jobs. The capable types come from [`Seek::Util.rdf_capable_types`](../lib/seek/util.rb#L66).

Consequences for RO-Crate:

- **On WorkflowHub, workflows are absent from the RDF and SPARQL side.** A workflow has JSON-LD and an RO-Crate, but
  no `.rdf` and nothing in the triple store. The experimental branch below is the first attempt to put workflow (and
  crate) metadata into the knowledge graph, by switching that graph from JERM to Schema.org.
- **ISA content is the reverse:** it has JERM RDF and SPARQL, but no RO-Crate.
- **The Bioschemas JSON-LD is the bridge.** It already describes workflows and is merged into generated crates
  (section 4), and the experimental branch proposes it as the source for the knowledge graph too.

### Research Object snapshots (RO-Bundle)

Investigations, Studies and Assays can be frozen as **snapshots**
([`acts_as_snapshottable.rb`](../lib/seek/research_objects/acts_as_snapshottable.rb),
[`snapshot.rb`](../app/models/snapshot.rb)). A snapshot is a
[Research Object Bundle](https://w3id.org/bundle/) (`.ro.zip`, media type `application/vnd.wf4ever.robundle+zip`),
built with the [`ro-bundle`](https://github.com/fbacall/ruby-ro-bundle) gem
([`generator.rb`](../lib/seek/research_objects/generator.rb), [`Gemfile#L93`](../Gemfile#L93)):

- The bundle's manifest aggregates each item in the ISA tree, with `pav:importedFrom` pointing back to SEEK.
- Each item gets a `metadata.json` ([`json_metadata.rb`](../lib/seek/research_objects/json_metadata.rb)) and a
  `metadata.rdf` holding its **JERM RDF** ([`rdf_metadata.rb`](../lib/seek/research_objects/rdf_metadata.rb)),
  alongside the files of its assets that the user may download.
- A snapshot can be given a DataCite DOI and deposited in Zenodo ([`snapshot.rb#L21-L22`](../app/models/snapshot.rb#L21-L22)).

So SEEK has two packaging formats side by side: RO-Bundle (with JERM RDF) for ISA snapshots, and RO-Crate (with
Schema.org) for workflows.

## History: from Research Objects to RO-Crate

The dates for SEEK below come from this repository's git history.

| When | In SEEK | In the Research Object community |
|---|---|---|
| 2008 | SEEK development starts (first commit 2008-10-08). | |
| 2010–2013 | | The [Wf4Ever](https://www.researchobject.org/) project develops *Research Objects*: aggregations of workflows, data and provenance described with ORE, the RO ontology and PROV. |
| 2012 | JERM RDF generation added (2012-11), with the JERM vocabulary and per-type RDF. | |
| 2013 | A first `Workflow` model, with inputs, outputs and an upload form (2013-10). This is the Taverna-era predecessor of today's workflow support. | |
| 2014 | | The [Research Object Bundle](https://w3id.org/bundle/) specification: a zip with a JSON-LD manifest, used by Taverna. |
| 2015 | `ro-bundle` gem added (2015-02); Investigation snapshots as RO-Bundles (2015-06), later with DOIs and Zenodo deposit. | |
| 2018–2019 | | RO-Crate starts, combining the Research Object approach with DataCrate and building on Schema.org rather than ORE. [RO-Crate 1.0](https://w3id.org/ro/crate/1.0) is released in 2019. |
| 2019 | Workflows downloadable as RO-Crates (2019-11-28): the start of the code described in this document, and of WorkflowHub. | |
| 2020s | WorkflowHub registers workflows as Workflow RO-Crates; git storage, TRS and Signposting are added around the crate; RO-Crate reading moves to the `ro-crate` gem. | RO-Crate [1.1](https://w3id.org/ro/crate/1.1) and later versions, profiles such as Workflow RO-Crate, Workflow Testing RO-Crate and the Workflow Run Crates. |
| 2025–2026 | SPARQL query page (2025-08); experimental Schema.org knowledge graph with RO-Crate metadata (branch, 2025-11 onwards). `ro-crate` gem 0.7.0 defaults to RO-Crate 1.3. | [REWIRE](https://esciencelab.org.uk/projects/rewire/) (from 2026-09) uses RO-Crate as the publishing and integration layer for reproducibility. |

What this means:

- **The snapshots are still on the pre-RO-Crate format.** RO-Bundle is superseded by RO-Crate, which most
  current tools expect. Moving ISA snapshots to RO-Crate would give SEEK one packaging format, and would let ISA
  content use RO-Crate profiles (for example [ISA RO-Crate](https://github.com/nfdi4plants/isa-ro-crate-profile) or
  ARC-style crates).
- **The two linked-data lines are converging on Schema.org.** JERM RDF has been SEEK's own vocabulary since 2012.
  The JSON-LD, RO-Crate and the experimental knowledge graph all use Schema.org, but replacing JERM loses the ISA
  types until they have Schema.org descriptions (the branch's `next-steps.md` proposes keeping both, chosen per site).

## Workflow RO-Crate in the literature

Four publications describe how Workflow RO-Crate and WorkflowHub are used beyond this code base. This section
summarises what each says about RO-Crate, and checks it against the code.

**Goble *et al.* (2023), "The EOSC-Life Workflow Collaboratory for the Life Sciences"**
[[1]](#ref-goble2023) places WorkflowHub in the ecosystem built by the EOSC-Life project: workflow management
systems, community repositories (Galaxy's Intergalactic Workflow Commission, nf-core), registries (BioContainers,
bio.tools, WorkflowHub), testing (LifeMonitor, OpenEBench) and execution services (Galaxy Europe, Sapporo, WfExS).
These are joined by a "Digital Object based Metadata Framework" of Bioschemas, EDAM, abstract CWL, RO-Crate and
GA4GH TRS. RO-Crate's role is stated as "the unit of currency of exchange between the services, recording the
provenance of workflow runs and a format for archiving in public repositories such as Zenodo". At the time it
reports "over 380 workflows ... from over 170 workflow teams", and adoption beyond the life sciences (biodiversity,
astronomy, astrophysics, climate change).

**Gustafsson *et al.* (2025), "WorkflowHub: a registry for computational workflows"** [[2]](#ref-gustafsson2025)
is the main WorkflowHub paper. It describes RO-Crate as "a fundamental unit that underpins upload, download, import
and export", stresses that "a user does not need to know how to create, or work with, RO-Crates as the registry
automatically builds a crate when a workflow is registered", and names Workflow RO-Crate 1.0 as the exchange format
with Zenodo and the basis for exposing workflows as FAIR Digital Objects. It also covers registering a
[Workflow Run RO-Crate](https://www.researchobject.org/workflow-run-crate/) to share a specific execution and its
provenance (example: [workflow 1072](https://workflowhub.eu/workflows/1072)), LifeMonitor test badges, TRS
integration with Galaxy, Sapporo and WfExS, CITATION.cff import, and DataCite DOIs. At submission it reports 860
workflows and 958 users from 266 organisations in 36 countries or locations. Its sustainability statement says that
at end of service "the published contributions and metadata will be archived as RO-Crates" in Zenodo. Future work
includes automated Git synchronisation and more TRS launch targets, with "the RO-Crate format ... central to this
effort".

**Wilkinson *et al.* (2025), "Applying the FAIR Principles to computational workflows"**
[[3]](#ref-wilkinson2025) interprets each FAIR principle for workflows, distinguishing a *workflow specification*
from a *workflow run*. Its worked examples use RO-Crate on both sides:

- **Specification:** the Protein MD Setup CWL workflow in WorkflowHub (DOI
  [10.48546/workflowhub.workflow.29.3](https://doi.org/10.48546/workflowhub.workflow.29.3)). "WorkflowHub's RO-Crate
  references that the embedded CWL code is archived from the corresponding GitHub source code repository", and the
  crate is the downloadable provenance for R1.3.
- **Run:** a digital pathology workflow run whose provenance was "generated using CWLProv in the form of RO-Bundle
  and then converted to an RO-Crate that follows the Provenance Run Crate profile". This is the RO-Bundle to RO-Crate
  transition from the history above, applied to run provenance.

It recommends Bioschemas ComputationalWorkflow metadata (as used in the Workflow Run Crate profiles) and points to
the Workflow RO-Crate profile for packaging a workflow with components "which also need to be FAIR".

**Wilkinson *et al.* (2026), "An ecosystem of services for FAIR computational workflows"**
[[4]](#ref-wilkinson2026) is chapter 4 of the book *Workflow systems for large-scale scientific data analysis*. It
combines the FAIR principles for workflows with the EOSC-Life Collaboratory as a worked ecosystem, and gives the most
detail on RO-Crate of the four:

- **Profiles.** It explains what an RO-Crate profile defines (required metadata, vocabularies, structural
  constraints, validation rules) and names three: Workflow RO-Crate, Workflow Testing RO-Crate, and Workflow Run
  RO-Crate (WRROC). Crates are "a currency of exchange" between WorkflowHub, LifeMonitor, OpenEBench and execution
  platforms.
- **Persistent identifiers.** "Effectively, RO-Crates are metadata objects referencing PIDs": attached and detached
  data entities, and contextual entities identified by ORCID, ROR and RAiD. It names "PID multiplicity" as a
  challenge (WorkflowHub entry, DOI, Git URL, a Zenodo DOI for the crate, a Software Heritage ID) and takes the
  WorkflowHub PID as the authority that gathers the others.
- **Signposting.** WorkflowHub is "an early adopter of FAIR signposting", using the Bibliographic Metadata and
  Publication Boundary patterns "to signpost the Workflow RO-Crate".
- **Archiving.** "The RO-Crate packaging means that every workflow in WorkflowHub can be deposited in other long
  term repositories like Zenodo or DataVerse, or even Software Heritage."
- **Workflow systems.** Galaxy, Snakemake, CWL and Nextflow support the framework natively, with RO-Crate enrichment,
  Workflow Run Crates for provenance, Git bot registration from IWC and nf-core, and TRS; Galaxy also exports data
  products as RO-Crates.
- **Life cycle.** Run records "are deposited in data repositories as Workflow-Run-RO-Crates, and occasionally
  registered in WorkflowHub to be published to support publications". Testing services gather and analyse
  provenance in RO-Crates.

### How the papers compare with the code

| Claim in the papers | In this code base (`main`) |
|---|---|
| RO-Crate underpins upload, download, import and export; a crate is built automatically [[2]](#ref-gustafsson2025) | Confirmed: sections 2 to 5. Uploaded crates are passed through; other workflows get a generated crate. |
| Workflow Run RO-Crates can be registered [[2]](#ref-gustafsson2025), and RO-Crate records run provenance [[1]](#ref-goble2023) | Partly. A run crate is accepted as an ordinary Workflow RO-Crate and served as uploaded: workflow 1072's crate declares the Process Run Crate and Workflow Run Crate 0.5 profiles and holds a `CreateAction`. Nothing in SEEK reads the run, so it is not shown, searched or linked. |
| Exchange with Zenodo and archiving as RO-Crates [[1]](#ref-goble2023), [[2]](#ref-gustafsson2025) | Not a feature. Zenodo deposit exists only for ISA snapshots ([`snapshot.rb#L22`](../app/models/snapshot.rb#L22)), which are RO-Bundles. Workflow crates reach Zenodo by other routes, and the end-of-service archive is a plan rather than code. |
| Workflow RO-Crate 1.0 [[2]](#ref-gustafsson2025) | Matches what generated crates declare, together with RO-Crate 1.3 from the gem (see the gaps below). |
| Workflows exposed as FAIR Digital Objects [[2]](#ref-gustafsson2025) | Supported through Signposting `item` links to the crate (section 5). |
| The crate records where the workflow came from [[3]](#ref-wilkinson2025) | `isBasedOn` and per-file `contentUrl` for git-backed workflows (section 4). |
| Signposting with the Bibliographic Metadata and Publication Boundary patterns [[4]](#ref-wilkinson2026) | Confirmed: `describedby` links (DataCite XML, JSON-LD, RDF where available) and an `item` link to the crate ([`fair_signposting.rb`](../app/controllers/concerns/fair_signposting.rb)). |
| Every workflow can be deposited in Zenodo, DataVerse or Software Heritage as an RO-Crate [[4]](#ref-wilkinson2026) | Possible because every version has a downloadable crate, but no deposit is built in (see the Zenodo row above). |
| The WorkflowHub PID is the authority that gathers the other PIDs [[4]](#ref-wilkinson2026) | Partly: the crate's `identifier` is the DOI if minted, otherwise the WorkflowHub URL, and `isBasedOn` holds the source repository. Zenodo DOIs and Software Heritage IDs are not recorded in the crate. |
| Contextual entities identified by ORCID and ROR [[4]](#ref-wilkinson2026) | ORCID for people (`Person#ro_crate_metadata`). Projects arrive through the merged Bioschemas `producer`, identified by their SEEK URLs; the workflow's Bioschemas description adds no ROR identifiers. |
| Growth: over 380 workflows and 170 teams (2023) [[1]](#ref-goble2023) to 860 workflows and 958 users (2025) [[2]](#ref-gustafsson2025) | Not derivable from code. |

### References

1. <a id="ref-goble2023"></a>Goble C, Bacall F, Soiland-Reyes S, Owen S, Eguinoa I, Droesbeke B, Ménager H,
   Rodriguez-Navas L, Fernández JM, Grüning B, Leo S, Pireddu L, Crusoe M, Gustafsson J, Capella-Gutierrez S,
   Coppens F (2023). The EOSC-Life Workflow Collaboratory for the Life Sciences. *Proceedings of the Conference on
   Research Data Infrastructure* 1. <https://doi.org/10.52825/cordi.v1i.352>
2. <a id="ref-gustafsson2025"></a>Gustafsson OJR, Wilkinson SR, Bacall F, Soiland-Reyes S, Leo S, Pireddu L, Owen S,
   Juty N, Fernández JM, Brown T, Ménager H, Grüning B, Capella-Gutierrez S, Coppens F, Goble C (2025). WorkflowHub:
   a registry for computational workflows. *Scientific Data* 12, 837. <https://doi.org/10.1038/s41597-025-04786-3>
3. <a id="ref-wilkinson2025"></a>Wilkinson SR, Aloqalaa M, Belhajjame K, Crusoe MR, de Paula Kinoshita B, Gadelha L,
   Garijo D, Gustafsson OJR, Juty N, Kanwal S, Khan FZ, Köster J, Peters-von Gehlen K, Pouchard L, Rannow RK,
   Soiland-Reyes S, Soranzo N, Sufi S, Sun Z, Vilne B, Wouters MA, Yuen D, Goble C (2025). Applying the FAIR
   Principles to computational workflows. *Scientific Data* 12, 328. <https://doi.org/10.1038/s41597-025-04451-9>
4. <a id="ref-wilkinson2026"></a>Wilkinson SR, Gustafsson J, Bacall F, Belhajjame K, Capella S, Fernandez Gonzalez JM,
   Fosso Tande J, Gadelha L, Garijo D, Grubel P, Grüning B, Khan FZ, Kanwal S, Leo S, Owen S, Pireddu L, Pouchard L,
   Rodríguez-Navas L, Serrano-Solano B, Soiland-Reyes S, Vilne B, Williams A, Wouters MA, Coppens F, Goble C (2026).
   An ecosystem of services for FAIR computational workflows. In: Leser U, Hilbrich M, Wilkinson SR, Ferreira da
   Silva R (eds), *Workflow systems for large-scale scientific data analysis*, chapter 4, pp. 113–145. Berlin
   Universities Publishing. ISBN 978-3-98781-067-1. <https://doi.org/10.14279/depositonce-25818>

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
  Crate) are not recognised.** They can be registered as ordinary Workflow RO-Crates and are served as uploaded
  (see [workflow 1072](https://workflowhub.eu/workflows/1072) and
  [How the papers compare with the code](#how-the-papers-compare-with-the-code)), but nothing interprets
  `CreateAction` entities, so runs are not shown, searched or linked to their workflow.
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

## Experimental and future work

### The `schema-knowledge-graph-messing` branch

[`schema-knowledge-graph-messing`](https://github.com/seek4science/seek/tree/schema-knowledge-graph-messing) is an
unmerged, experimental branch (reviewed here at `20b0cec542`, 2026-11-16). Its main aim is a knowledge graph:
replacing the JERM RDF sent to the triple store with the Schema.org / Bioschemas JSON-LD that pages already embed,
and adding each Workflow's RO-Crate metadata to that graph. The branch documents itself in
[`docs/schema-kg-work.md`](https://github.com/seek4science/seek/blob/schema-knowledge-graph-messing/docs/schema-kg-work.md)
(an evaluation that calls it "a proof of concept" that "is not mergeable as it stands") and
[`next-steps.md`](https://github.com/seek4science/seek/blob/schema-knowledge-graph-messing/next-steps.md) (a staged
plan, with the vocabulary chosen per site through a `profile` column in the RDF CSV mappings). Those documents cover
the RDF side in detail; this section covers what the branch changes for RO-Crate.

**What it adds for RO-Crate:**

- **RO-Crate metadata in the knowledge graph.** A new `Workflow#ro_crate_metadata` returns the latest version's
  `ro-crate-metadata.json` with an extra `@base` of `<workflow URL>/crate/`, so crate entities get absolute IRIs.
  The RO-Crate 1.1, 1.2 and 1.3 JSON-LD contexts are shipped in `lib/seek/rdf/json_ld_contexts/` and preloaded, so
  RDF generation doesn't fetch them over the network. `http://schema.org/` is normalised to `https://schema.org/`,
  and the crate's own context is kept so that `ComputationalWorkflow` gets the same Bioschemas IRI as SEEK's own
  JSON-LD.
- **SPARQL example queries** that list RO-Crates, workflow files, and CWL workflows by language identifier.
- **Richer Bioschemas, which also flows into generated crates** (through `merge_entities`, section 4): workflow
  topics and operations (EDAM) and disciplines (OpenAlex fields) as `DefinedTerm`s, and a fixed diagram `image` URL.
  The diagram fix is a bug on `main` that `next-steps.md` recommends for `seek-1.19`.
- **Regenerating uploaded crates.** Two new settings, on the admin "Features enabled" page:
  `regenerate_workflow_ro_crates` (default `true`) and `workflow_ro_crate_regeneration_strategy` (default
  `replace_all`; also `replace_seek`, `fill_missing` and `new_crate`). With these, SEEK writes its own metadata into
  crates that were uploaded as full RO-Crates, which on `main` are served exactly as uploaded.
- **New defaults:** `workflows_enabled` and `git_support_enabled` become `true`.

**Points to resolve before any of this is merged.** These are additional to the branch's own list:

1. **Uploaded crates would change by default.** With `regenerate_workflow_ro_crates` on by default, WorkflowHub
   would serve a different crate from the one that was uploaded, including for versions that already have a DOI.
   This addresses the "uploaded crates are not rewritten" gap above, but it changes published content. It needs a
   decision on defaults, and probably a way to keep the uploaded crate available.
2. **The strategies only govern the main workflow entity.** `populate_ro_crate` is unchanged on the branch and still
   assigns the crate's root `author`, `license`, `identifier` and `url`, and `merge_entities` sets root `name` and
   `description`, with every strategy. So `fill_missing` and `replace_seek` don't keep the uploader's root metadata,
   although the branch's documentation says SEEK's values are "only added where the upload has none".
3. **The strategy tests don't cover crates stored in git, which is how WorkflowHub stores uploads.** All the
   regeneration tests use `existing_galaxy_ro_crate_workflow`, a crate kept as a content blob (the legacy path). In
   the git path, `populate_ro_crate` builds a new main workflow entity from the git blob. The gem's
   [`add_data_entity`](https://github.com/ResearchObject/ro-crate-ruby/blob/v0.7.0/lib/ro_crate/model/crate.rb#L166-L171)
   replaces any entity with the same `@id`, so the uploader's main-workflow properties (for example inputs and
   outputs) would be dropped before any strategy applies. *Not yet verified by running the code;* whether the later
   `add_all` call also replaces the other file entities is also unchecked.
4. **The new defaults affect every SEEK site.** Sites that never set `workflows_enabled` or `git_support_enabled`
   would probably get workflows switched on after upgrading. `next-steps.md` keeps these defaults out of 1.19, but
   doesn't settle them for `main`.
5. **Versions and visibility.** The RDF copy uses the latest version's crate regardless of that version's own
   visibility (noted in the branch's evaluation). The RO-Crate 1.3 / Workflow RO-Crate 1.0 mismatch is unchanged.
6. **One method name, two contracts.** `Workflow#ro_crate_metadata` returns a JSON-LD string, while
   `Person#ro_crate_metadata` and `Project#ro_crate_metadata` return hash fragments for embedding in crates. The
   branch's own plan is to rename the new method.

### Other future work

Gaps above that no branch addresses yet:

- Declaring [Workflow RO-Crate 1.1](https://about.workflowhub.eu/Workflow-RO-Crate/1.1/) (or pinning the RO-Crate
  version the profile is based on).
- Recognising [Workflow Run Crates](https://www.researchobject.org/workflow-run-crate/), for example showing recorded
  runs of a workflow and their provenance.
- Validating uploads with [rocrate-validator](https://github.com/crs4/rocrate-validator) and its Workflow RO-Crate
  profile, and reporting the result.
- Documenting the RO-Crate endpoints in the OpenAPI definition, and the RO-Crate settings in the SEEK administration
  guide.
- RO-Crate export for other SEEK types (ISA, DataFile), in place of the RO-Bundle snapshots.

Two projects make these concrete:

- **[REWIRE](https://esciencelab.org.uk/projects/rewire/)** (Horizon Europe, 2026–2029) uses RO-Crate as the
  publishing and integration layer for reproducibility, and adapts the Process Run, Workflow Run and machine-actionable
  DMP RO-Crate profiles.
- **The [BioFAIR](https://esciencelab.org.uk/projects/biofair/) Methods Commons** (UKRI, from July 2026) makes
  WorkflowHub the single access point for UK life-science workflows, with a curated "BioFAIR Workflow Collection", a
  "Shared Project Space" that uses Workflow Run RO-Crate provenance and FAIRDOM-SEEK cataloguing, a "Workflow
  Observatory" for quality, and RO-Crate and GA4GH as its API standards. That needs SEEK to read run crates and link
  them to workflows and data, which `main` does not do.

Both are written up as a plan in [`rewire-blueprint.md`](rewire-blueprint.md).
