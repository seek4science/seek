# Evaluation: `schema-knowledge-graph-messing` branch

Evaluated against `main` at `766000e3a4` (merge base) on 2026-11-10.

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

  I didn't run the tests: the latest `main` merge needs gems that aren't installed locally
  (`crass-1.0.8`). These failures come from reading the code and should be confirmed with a
  test run.

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
> regenerated, because data sent before this change has no item graph and so can't be removed. A privacy change to a
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

The RO-Crate `@context` is a remote URL (`https://w3id.org/ro/crate/1.1/context`, a 302 redirect
to researchobject.org). The JSON-LD reader fetches it every time it parses. That is why the test
needs a VCR cassette. In production, every Workflow RDF generation makes two HTTP requests, and
the job fails or hangs if w3id.org is unreachable. `send_rdf` calls `item.to_rdf` up to three
times: in the debug log interpolation, in `with_statements`, and in `save_rdf_file`. So this
happens several times per job.

Preload the context with `JSON::LD::Context.add_preloaded`, ship the context file in the repo
(ro_crate_ruby may already bundle it), or build the RO-Crate graph from the expanded form.

### 5. Major: Workflow RO-Crate generation is heavy and unguarded

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
3. **Store one named graph per item** (inside the public and private split, or with visibility
   recorded on the graph), so updates and removals are exact and blank nodes and foreign-subject
   triples stop accumulating.
4. **Normalise to a single Schema.org namespace** and add a test that checks it.
5. **Remove network access from RDF generation** by preloading the RO-Crate context, and wrap
   RO-Crate generation in error handling. Consider caching it per version, since a version's crate
   is immutable once frozen.
6. **Update or replace the failing tests and `config/sparql_queries.yml`**, and give the new
   triple-store test real assertions, for example a `schema:name` triple per type and namespace
   checks.
7. **Make the RDF-capable type list and the models that include `RdfGeneration` agree**, so that
   `.rdf` and FAIR Signposting never advertise something that raises.
8. Tidy up the debug output, the commented code and the `ro_crate_metadata` naming before review.
