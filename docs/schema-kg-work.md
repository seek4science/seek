# Evaluation: `schema-knowledge-graph-messing` branch

Evaluated against `main` at `766000e3a4` (merge base) on 2026-11-10. Status notes on each problem, and the
[Work since the evaluation](#work-since-the-evaluation) section, were updated on 2026-11-12 (up to `cd7b338bc2`).

## Summary

The branch is a **proof of concept**. It switches what SEEK sends to the triple store from the
hand-curated JERM/Dublin Core triples (`rdf_mappings.csv`) to the Schema.org / Bioschemas JSON-LD
already produced by `to_schema_ld`. For Workflows it also adds the RO-Crate metadata. The core idea
is simple and works: parse the JSON-LD with `RDF::Reader.for(:jsonld)` and add the statements to
the graph. That one public description of each item then drives the HTML `<script>` block, the
`.jsonld` endpoint and the knowledge graph.

It is not mergeable as it stands. Existing RDF features have been commented out rather than
replaced, debug output is left in, the existing RDF tests will fail, and there are design problems
around namespaces, stale triples and network access that need resolving first.

The useful branch-specific changes are small (about 60 lines of code, plus a 5.5k-line VCR
cassette). The earlier commits in the branch history (`#2386`, the JSON-LD endpoints work) are
already on `main`.

## What changed

| File | Change |
|---|---|
| `lib/seek/rdf/rdf_mappings.csv` | ~75 JERM/DC/FOAF/SIOC mapping rows deleted. It now holds three rows: `*,to_schema_ld,nil,j`, `Workflow,ro_crate_metadata,nil,j`, and the existing `Person,mbox_sha1sum` row. The column header is renamed to `uri literal or statements`. |
| `lib/seek/rdf/csv_mappings_handling.rb` | New `j` mode. The method's return value is treated as a JSON-LD string, parsed into statements and appended to the graph. The `property` column and the subject resource are ignored in this mode. |
| `lib/seek/rdf/rdf_generation.rb` | `to_rdf_graph` comments out `describe_type`, `additional_triples`, `extended_metadata_triples` and `sample_metadata_triples`. Adds a `schema` prefix (`http://schema.org/`). |
| `lib/seek/rdf/rdf_repository.rb` | `send_rdf` gates on `schema_org_supported?` instead of `rdf_supported?`, and adds `pp statement`. |
| `lib/seek/util.rb` | `rdf_capable_types` now returns `schema_org_supported_types`. |
| `app/models/workflow.rb` | New `Workflow#ro_crate_metadata`. It generates the latest version's RO-Crate metadata, replaces `@context` with RO-Crate 1.1 plus `@base: <workflow url>/crate/`, and returns JSON. There is also a commented-out `to_schema_ld` stub. |
| `test/integration/rdf_triple_store_test.rb` | `@project` now uses `:max_project`. Adds a `send schema to store` test that sends a workflow, data file, person and institution. The test has no assertions, uses `pp` debug output, and has a commented-out line. |
| `test/vcr_cassettes/workflow/ro_crate_context.yml` | Recording of the fetch of the remote RO-Crate 1.1 context (recorded twice: 302 redirect, then the body). |

## What works well

- **One source of truth.** The Bioschemas decorators are maintained, tested and already published
  in pages and the API. Reusing them for the graph removes the JERM/CSV mapping as a parallel
  description that drifts out of date.
- **Better vocabulary for interoperability.** Schema.org triples are much easier for outside
  consumers to query than JERM, which is effectively SEEK-specific.
- **The `j` mode is a small, contained mechanism.** Any method that returns JSON-LD can feed the
  graph. The RO-Crate addition shows this extends beyond the Bioschemas output.
- **Public-only associations.** `mini_definitions` skips non-public related items, so a public
  item's graph does not leak the names of private related items.

## Problems

### 1. Blocking: features and tests from `main` regress

- **Extended metadata and sample attribute RDF are switched off.** `extended_metadata_triples` and
  `sample_metadata_triples` are commented out. Both are recent work on `main` (#2595, typed
  literals and blank-value skipping). Nothing replaces them in the JSON-LD path, so EMT and sample
  attributes with PIDs no longer reach the graph. The SBML format triple (`additional_triples`) is
  also gone.
- **The set of RDF-capable types changes in both directions.** `rdf_capable_types` was
  `Assay DataFile Investigation Model ObservationUnit Organism Person Programme Project Publication
  Sample Sop Strain Study`. It now equals the Bioschemas types.
  - **Types that lose RDF:** Assay, Study, Investigation, Model, ObservationUnit, Strain and
    Publication. `.rdf` requests now return 406 (`ApplicationController#rdf_enabled?`). The FAIR
    Signposting `describedby rdf` link disappears. Their triples are never removed from the store
    either, because `remove_rdf` and `update_rdf` still check `rdf_supported?`. **The whole ISA
    structure leaves the knowledge graph.**
  - **Types that gain RDF without the code to back it:** Event, Presentation and AssetsCreator
    don't include `Seek::Rdf::RdfGeneration`. `rdf_enabled?` now lets `.rdf` requests through
    for them, and FAIR Signposting advertises an RDF link. For Presentation,
    `AssetsStandardControllerActions` renders `rdf/show`, which calls `to_rdf`, so expect a
    `NoMethodError` (500). Event and the others depend on how each controller handles `.rdf`.
- **`config/sparql_queries.yml` breaks.** The example query library behind the SPARQL UI uses the
  `jerm:` prefix about 45 times. None of those predicates are emitted any more, so every example
  query returns nothing.
- **Existing tests will fail**, including:
  - `test/unit/util_test.rb`: the expected `rdf_capable_types` list.
  - `test/unit/rdf_generation_test.rb`: `rdf_supported?` expectations (it asserts Assay is
    supported and Event, Institution and Document are not), and JERM `rdf_type_uri`.
  - `test/integration/rdf_triple_store_test.rb` `send to store`: asserts `dcterms:title` and an
    `xsd:dateTime` `dcterms:created`. The JSON-LD has neither, and dates arrive as plain strings.
  - Per-model `to_rdf` tests in about 15 unit test files, plus `rdf_response_test.rb` and
    `sparql_queries_test.rb`.

  > **Status: still open.** Test runs since the evaluation confirm these failures (the full suite hasn't been run):
  > - `sparql_queries_test.rb`: the 15 JERM example queries return nothing. The Schema.org example queries added
  >   since all pass.
  > - `rdf_triple_store_test.rb`: `send to store`, `update rdf`, `update rdf after resource type change` and
  >   `update rdf change visibility`, which all assert `dcterms:title`.
  > - `sparql_controller_test.rb`: 3 tests, and `rdf_generation_job_test.rb`: 3 tests.
  > - `rdf_generation_test.rb`: the EMT triples and `rdf_supported?` expectations.
  > - `workflows_controller_test.rb` `should return 406 when requesting RDF`: Workflow is now RDF capable, so the
  >   request returns 200.

### 2. Blocking: Schema.org namespace mismatch (`http` vs `https`)

> **Status: addressed.** `RdfGeneration#jsonld_statements` rewrites `http://schema.org/` terms to
> `https://schema.org/` when JSON-LD is read in, and the `schema` prefix is now `https://schema.org/`. Covered by a
> unit test in `rdf_generation_test.rb` and a workflow update test in `rdf_triple_store_test.rb`. The Bioschemas
> types now match as well: `Workflow#ro_crate_metadata` used to replace the crate's own RO-Crate 1.3 context with
> 1.1, which maps `ComputationalWorkflow` to `https://bioschemas.org/ComputationalWorkflow`. It now keeps the 1.3
> context (only adding `@base`), which uses `https://bioschemas.org/terms/ComputationalWorkflow`, the same IRI as
> SEEK's Bioschemas output.

The Bioschemas serializer uses `@vocab: https://schema.org/`. The RO-Crate 1.1 context maps terms
to `http://schema.org/` (for example `"Dataset": "http://schema.org/Dataset"` in the cassette).
The new `schema` prefix in `ns_prefixes` is also `http://schema.org/`.

As a result, a Workflow gets `https://schema.org/name` from `to_schema_ld` and
`http://schema.org/name` from its RO-Crate. Every other type gets `https` only. Queries must use
both namespaces or they silently miss data. Choose one form (Schema.org itself recommends treating
them as equivalent, but a triple store does not), and either rewrite on ingest or set the
Bioschemas context to match.

### 3. Major: stale and orphaned triples build up in the store

> **Status: addressed** in `lib/seek/rdf/rdf_repository.rb`. Each item's statements also go into a per-item named
> graph (`<private_graph>/items/<Class>/<id>`) that records which aggregate graphs it fed (`dcterms:isPartOf`).
> Removal deletes from each aggregate graph only the statements no other contributing item graph still holds, then
> drops the item graph. Blank nodes are skolemized to `<site>/.well-known/genid/<uuid>`. Before this change they
> were also disconnected, because each statement went in a separate `INSERT`. Inserts are now batched (200 per
> request). Covered by new tests in `test/integration/rdf_triple_store_test.rb`. Existing stores must be cleared and
> regenerated, because data sent before this change has no item graph and so can't be removed. The admin
> "Regenerate all RDF" button does both. A privacy change to a
> related item still only clears its name from other items' graphs once those items regenerate: `Policy` enqueues
> with `refresh_dependents: false`.

`remove_rdf` deletes only `<item> ?p ?o`. The old CSV output only ever had the item as subject,
so that was enough. The JSON-LD output does not:

- Associated items' `mini_definition`s produce triples about **other** subjects, such as
  `<person/5> schema:name "…"` and `<project/2> a schema:Project`. When this item is regenerated,
  those triples are not removed. A renamed related item keeps its old name in this item's graph
  until the related item is itself removed, and even then only its own subject triples go.
- Nested objects without an `@id` (distributions, `PropertyValue`s, the Sample `propertyId`
  values, RO-Crate contextual entities) become **blank nodes**. Each regeneration inserts fresh
  blank nodes and none are ever deleted, so the store grows on every update.
- RO-Crate entities are minted under `<workflow url>/crate/…` via `@base`. They have no owner from
  `remove_rdf`'s point of view and are never cleaned up.
- A related item that is public now but later made private stays named in other items' public
  graph.

A **named graph per item** fixes this cleanly: drop the item's graph and reinsert it. Otherwise,
blank nodes need skolemising and deletion has to cover every subject the item emitted (for
example by tracking subjects, or deleting by `prov`/`dct:source` provenance).

### 4. Major: RDF generation makes network calls

> **Status: addressed.** The RO-Crate 1.1, 1.2 and 1.3 JSON-LD contexts (CC0) are kept in
> `lib/seek/rdf/json_ld_contexts/`, and `Seek::Rdf::JSONLdContexts.preload` registers them with
> `JSON::LD::Context.add_preloaded` at boot, so they are never fetched. The VCR cassette is gone. A test checks that
> each context resolves while WebMock blocks HTTP. A crate declaring a newer RO-Crate version would still be fetched
> until its context is added.

The RO-Crate `@context` is a remote URL (`https://w3id.org/ro/crate/1.1/context`, a 302 redirect
to researchobject.org). The JSON-LD reader fetches it every time it parses. That is why the test
needs a VCR cassette. In production, every Workflow RDF generation makes two HTTP requests, and
the job fails or hangs if w3id.org is unreachable. `send_rdf` calls `item.to_rdf` up to three
times: in the debug log interpolation, in `with_statements`, and in `save_rdf_file`. So this
happens several times per job.

Preload the context with `JSON::LD::Context.add_preloaded`, ship the context file in the repo
(ro_crate_ruby may already bundle it), or build the RO-Crate graph from the expanded form.

### 5. Major: Workflow RO-Crate generation is heavy and unguarded

> **Status: still open.** None of the four points below has been changed. Two related changes since the
> evaluation:
> - By default SEEK now regenerates the RO-Crate of a workflow uploaded as a full RO-Crate
>   (`regenerate_workflow_ro_crates`, see [Work since the evaluation](#work-since-the-evaluation)), so the graph's
>   copy of the crate now carries SEEK's metadata rather than the uploader's. This adds to the cost per
>   regeneration, as the uploaded crate is opened and then merged.
> - The proposed fix for the disconnected nodes (the last point) is to add
>   `<workflow> schema:workExample <…/crate/main-workflow-file>` and `<workflow> schema:subjectOf <…/crate/>` to the
>   RDF copy of the crate only, in `Workflow#ro_crate_metadata`. This hasn't been implemented.

- `latest_version.ro_crate.metadata` builds the full RO-Crate model, including walking the git
  tree, on every RDF regeneration. RDF regeneration happens on every save and for dependents.
- Any error (missing git objects, a bad main workflow path, a remote file) raises from inside
  `RdfGenerationJob`. There is no rescue, unlike the Rightfield path.
- It always uses `latest_version`. Workflow versions can have their own visibility, and the
  item's graph target is chosen from `can_view?(nil)` on the parent. So a private latest version
  could go into the public graph, or a public one could be withheld. This needs a decision on
  which version, or versions, belong in the graph.
- The RO-Crate `./` root entity and the Bioschemas entity for the workflow are two different
  subjects (`<wf>/crate/` and `<wf>`) with nothing linking them. The data is in the graph, but it
  is disconnected from the item's own node.

### 6. Minor: the CSV mapping is now vestigial

> **Status: still open.**

With three rows, two of which ignore the `property` column (`nil`) and the subject, the CSV plus
`eval` machinery adds indirection without benefit. An explicit method would be clearer, for
example:

```ruby
def to_rdf_graph
  graph = RDF::Graph.new
  graph << jsonld_statements(to_schema_ld) if schema_org_supported?
  graph << jsonld_statements(ro_crate_metadata) if respond_to?(:ro_crate_metadata_jsonld)
  ...
end
```

This also avoids the `*` row matching `to_schema_ld` on types where `respond_to?` happens to be
true but `schema_org_supported?` is false. One example is `Git::Version`, which defines
`to_schema_ld` itself.

Note the naming clash: `Project#ro_crate_metadata` and `Person#ro_crate_metadata` already exist
and return a *Hash fragment* for embedding in crates. `Workflow#ro_crate_metadata` returns a
*JSON-LD String document*. The `Workflow` CSV row is class-scoped, so this doesn't break today,
but one method name with two contracts is a trap. Rename it, for example
`ro_crate_metadata_jsonld`.

### 7. Minor: housekeeping

> **Status: partly addressed.**
> - Done: `pp statement` is gone from `RdfRepository#send_rdf`, and `send_rdf`, `remove_rdf` and `update_rdf` all
>   gate on `rdf_supported?`.
> - Still open: the `pp` calls, the missing assertions and the commented-out line in the `send schema to store`
>   test; the `to_schema_ld` stub in `workflow.rb`; the four commented-out calls in `to_rdf_graph`; the
>   `rdf_capable_types` / `schema_org_supported_types` aliasing; the unused JERM leftovers; `to_json_ld`; and the
>   merge history.

- `pp statement` in `RdfRepository#send_rdf`, and `pp person.to_rdf` / `pp inst.to_rdf_graph` in
  the test.
- The new test has no assertions, so it only checks that nothing raises.
- Commented-out code: the `to_schema_ld` stub in `workflow.rb`, the four calls in `to_rdf_graph`,
  and `# @repository.send_rdf(@project)` in the test.
- Inconsistent gating: `send_rdf` checks `schema_org_supported?` while `remove_rdf` and
  `update_rdf` check `rdf_supported?`. These currently mean the same thing for top-level models
  but should use one predicate.
- `rdf_capable_types` and `schema_org_supported_types` are now aliases. Either collapse them or
  keep them distinct on purpose.
- Unused leftovers from the old path: `describe_type`, `rdf_type_uri` and `JERMVocab.defined_types`
  for RDF.
- `to_json_ld` (the RDF→JSON-LD round trip) is now a lossy way to get back roughly the JSON-LD the
  item started with.
- The merge history (several merges from `seek-1.17` and `main`, plus a revert pair) should be
  squashed or rebased if this becomes a PR.

## Work since the evaluation

All on this branch, in order. Most commits carry `[skip ci]`.

### Triple store

- **Per-item named graphs** (`bb9f93a956`): see problem 3. Each item's statements are also stored in
  `<private_graph>/items/<Class>/<id>`, so removal is exact. Blank nodes are skolemized and inserts batched.
- **Clearing the store** (`d05641cfb0`): `RdfRepository#clear_all` drops the public and private graphs and every
  item graph. `RdfRepository#item_graph_uris` lists the item graphs.

### RDF generation

- **One Schema.org namespace** (`7cc0a73c1f`): see problem 2.
- **The RO-Crate's own context is kept** (`15144395c7`), so the crate's `ComputationalWorkflow` uses the same
  Bioschemas IRI as SEEK's own output.
- **Relative IRIs are resolved against the item's URL** (`741dd2c675`). Before this, statements using relative
  IRIs such as `#cwl` were dropped, so the workflow's `programmingLanguage`, inputs and outputs were missing from
  the graph.
- **Preloaded RO-Crate contexts** (`c30d00ab4a`): see problem 4.
- **Workflow topics, disciplines and operations** (`1edcf0aa88`): the Bioschemas output now has topics (EDAM) and
  disciplines (OpenAlex fields) as `schema:about`, and operations (EDAM) as `schema:featureList`. Each is a
  `DefinedTerm`, with `inDefinedTermSet` (`http://edamontology.org` or `https://openalex.org/fields`) when its IRI
  belongs to that set. These appear in the page JSON-LD, the knowledge graph and generated RO-Crates.

### Workflow RO-Crates

- **Regenerating uploaded crates** (`9e35220638`, `d05641cfb0`): before this, a workflow uploaded as a full
  RO-Crate (not a "basic" one) was served exactly as uploaded, with none of SEEK's metadata. Two settings, on the
  admin Features enabled page under Workflows, now control this:
  - `regenerate_workflow_ro_crates` (default `true`): whether SEEK adds its metadata to uploaded crates.
  - `workflow_ro_crate_regeneration_strategy` (default `replace_all`): how it does so.

  | Strategy | Uploaded main workflow metadata |
  |---|---|
  | `replace_all` | SEEK's values replace the uploaded ones. Fields only the upload has are kept. |
  | `replace_seek` | Only the fields describing SEEK's record are replaced (`url`, `identifier`, `isBasedOn`, `contributor`, `producer`, `creator`, `license`, `version`, the dates and `sdPublisher`). Others are only added if missing. |
  | `fill_missing` | SEEK's values are only added where the upload has none. |
  | `new_crate` | A new crate holding the uploaded files, described only by SEEK. |

  Blank SEEK values never replace uploaded ones, and `@id`, `@type`, `image` and `subjectOf` are never replaced.
  With the replace strategies, uploaded entities that nothing refers to any more are removed. Workflows uploaded
  as plain files, and basic crates, still only get missing values added, as before.

### SPARQL UI

- **Schema.org example queries** (`853e75642a`, `644bc68c78`, `ee805171cb`, `1edcf0aa88`): people, workflows, CWL
  workflows by language identifier, RO-Crates, workflow files, and workflows with their disciplines, topics and
  operations. `sparql_queries_test.rb` seeds an annotated public workflow so that each returns results.
- **Queries use GET** (`bca1417578`), so the back button doesn't resubmit the form.
- **Tooltips** (`cb48668857`) show the full value of truncated links in the results.

### Admin and configuration

- **Regenerate all RDF** (`9e35220638`, `d05641cfb0`): a button on the admin page queues `RdfRegenerateAllJob`.
  The job clears the triple store, then queues RDF generation for every RDF capable item through
  `RdfGenerationQueue.enqueue_all`. `rake seek_rdf:generate` uses the same method, but doesn't clear the store.
- **New defaults**: `workflows_enabled` (`7da01532a4`) and `git_support_enabled` (`cd7b338bc2`) are now `true`.

### Docker

- **`docker-compose-virtuoso.yml`** (`7da01532a4`, `01751845b4`): the volumes are prefixed `kg-`, and the fixed
  container names are gone.
  - Virtuoso's HTTP port (SPARQL and Conductor) is published on host port 9890, and its isql port on
    127.0.0.1:9111. `VIRTUOSO_PORT` and `VIRTUOSO_ISQL_PORT` change these.
  - SEEK still reaches it at `virtuoso:8890` within the compose network.
  - The file shares the default project name `seek` (from the directory) and its service names with
    `docker-compose.yml`, so starting it replaces the main stack's containers. Give it its own project name
    (`name:` in the file, or `-p`) to run both.

## Recommendations

1. **Decide the model before polishing.** Should Schema.org fully *replace* JERM in the graph, or
   sit *alongside* it? Replacing it drops ISA types (Assay, Study, Investigation, Model,
   ObservationUnit, Strain, Publication) that have no Bioschemas decorator. Alongside is the
   lower-risk route: keep the CSV/JERM triples, add the JSON-LD statements, and
   `rdf_capable_types` stays as it is. Replacing it requires Bioschemas decorators, or an
   ISA-specific JSON-LD, for every ISA type first.
2. **Restore EMT and sample-attribute triples.** Either keep them as additional triples, or emit
   them as `additionalProperty`/`PropertyValue` in the JSON-LD (this would also make them visible
   on the page).
3. ~~**Store one named graph per item**~~ (done, see problem 3).
4. ~~**Normalise to a single Schema.org namespace**~~ (done, see problem 2).
5. ~~**Remove network access from RDF generation**~~ (done, see problem 4). Still to do: wrap
   RO-Crate generation in error handling. Consider caching it per version, since a version's crate
   is immutable once frozen.
6. **Update or replace the failing tests and the JERM queries in `config/sparql_queries.yml`** (the
   Schema.org example queries are done), and give the new
   triple-store test real assertions, for example a `schema:name` triple per type and namespace
   checks.
7. **Make the RDF-capable type list and the models that include `RdfGeneration` agree**, so that
   `.rdf` and FAIR Signposting never advertise something that raises.
8. Tidy up the debug output, the commented code and the `ro_crate_metadata` naming before review.
