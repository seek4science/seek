# Next steps for the Schema.org knowledge graph branch

Branch: `schema-knowledge-graph-messing`. It contains all of `main`, and `main` is only three commits
ahead of `seek-1.19`. This doc covers:

1. Small fixes on this branch that are also worth taking to `seek-1.19`.
2. A plan to bring the branch into `main` for the next release.
3. How SEEK could produce the JERM RDF, the Schema.org/RO-Crate RDF, or both, chosen through the CSV
   mappings file.

For the background and the problems found so far, see `docs/schema-kg-work.md`.

## 1. Small fixes suitable for `seek-1.19`

Each of these fixes something that is also broken, or worth having, on `seek-1.19`. None of them
depends on the switch to Schema.org. Most should cherry-pick cleanly. Where they don't, the change
is small enough to redo by hand.

### Recommended

| Commit | What | Why it applies to 1.19 |
|---|---|---|
| `8957927262` | Show every statement of a DESCRIBE or CONSTRUCT query's results | `SparqlController#execute_sparql_query` calls `empty?` on the `RDF::NTriples::Reader`. That consumes the first statement, so the first triple is always missing from the results. The bug is on `main`. |
| `8023616731` | Give the SPARQL results table a column for each query variable, in order | The table takes its headings from the first row's keys. A row leaves out unbound variables, so columns go missing or shift (for example with `OPTIONAL`). Depends on `f232da9be1` for the helper, unless the column helper is taken on its own. |
| `bca1417578` | Submit SPARQL queries with GET | Going back in the browser re-submits the form. GET also makes a query's results bookmarkable. Small route and view change. |
| `51b8c76ef9` | Regenerate the person's and project's RDF when a project membership changes | The JERM mappings include `Person,projects,JERMVocab.isAssociatedWith`, so the RDF on 1.19 goes stale in the same way. |
| `3c6198999b` | Run RDF jobs on their own queue, with a single one-thread worker | Since the move to Solid Queue, RDF jobs share a queue with other work, and concurrent updates to the triple store can interleave. Small config and job change. |
| `0718d33736` | Name the Redis container started by the scripts `seek-cache` | The `script/*-docker-redis.sh` scripts and `docker-compose.yml` (`seek-redis`) clash on 1.19 too. Scripts only. |
| `ee0f533f70` (one line of it) | A workflow version's diagram URL uses the workflow's id | `Seek::BioSchema::ResourceDecorators::Workflow#image` passes the `Workflow::Version` to `diagram_workflow_url`, so the URL contains the version record's id. That is a broken link in the JSON-LD served on 1.19. Take only the `parent_resource` change. The `can_render_diagram?` change matters only for RDF generation. |

### Triple store updates through named graphs, and the regenerate all RDF button

These are bigger than the fixes above, but they don't depend on the vocabulary and they fix a real
problem on 1.19. An item's old RDF is removed by deleting the statements it produces now, so
anything it no longer produces is never removed, and the store builds up out-of-date triples. The
triple store needs rebuilding once after upgrading, which is acceptable. Add this to the release
notes. These should go in their own PR.

| Commit | What | Notes |
|---|---|---|
| `bb9f93a956` | Store each item's RDF in its own named graph, so it can be removed exactly | Each aggregate graph keeps any statement that another item graph also holds. Blank nodes are turned into fixed IRIs (skolemized) so they can be removed again, which matters for the JERM extended metadata's blank nodes. |
| `277366b6fc` | Update an item's RDF with a single, atomic request | Virtuoso applies the removal and the insertion as one transaction, so a query never sees an item half updated. |
| `9e35220638` (in part) | Admin button to regenerate all RDF | The button, its route, `RdfRegenerateAllJob` (not on 1.19), `RdfGenerationQueue.enqueue_all`, and the rake task change. Leave out the setting to regenerate uploaded workflow RO-Crates. |
| `d05641cfb0` (in part) | Clear the triple store before regenerating all RDF | `RdfRepository#clear_all` and its use in `RdfRegenerateAllJob`. Leave out the RO-Crate regeneration options. |

How to do it:

- **Copy the repository rather than cherry-picking.** `bb9f93a956` and `277366b6fc` don't cherry-pick
  cleanly. The conflicts come from earlier commits on this branch that also changed
  `rdf_repository.rb`, not from anything to do with Schema.org. Copy the final
  `lib/seek/rdf/rdf_repository.rb`, which has nothing Schema.org-specific in it and builds its
  statements from `to_rdf_graph`.
- **Tests:** take this branch's triple store tests, but put the assertions back to `main`'s JERM
  versions (`dcterms:title`, `dcterms:modified`, `jerm:Data` and `jerm:Simulation_data`).
- **Separate RDF queue:** take `3c6198999b` (above) at the same time. Regenerating everything queues
  a lot of jobs, and a one-thread worker stops them updating the store at the same time.
- **Check the regenerate list.** On 1.19 the list of types to regenerate comes from
  `JERMVocab.defined_types`. Check that every type in it generates RDF, so the job doesn't queue
  items that do nothing. On this branch that happened with AssetsCreator.

### Optional (UI improvements rather than fixes)

| Commit | What |
|---|---|
| `f232da9be1` | Tell IRIs, blank nodes and literals apart in the SPARQL results, with `<>` around IRIs. Needed if `8023616731` is taken as it is. |
| `cb48668857` | Show the full value of a truncated link in the SPARQL results as a tooltip. |
| `77902a547e` | Font fix for the above. Only needed with `f232da9be1`. |

### Not for 1.19

- **Everything that changes what RDF is produced:** the Schema.org CSV rows, the ROR enrichment, the
  Publication decorator, Event and Presentation RDF, and the `rdf_capable_types` change.
- **`751807293b`** (regenerate RDF when annotations change): the JERM mappings have no rows for tags
  or controlled vocabulary annotations. Its `delete_all` → `destroy_all` change now runs the
  callbacks of annotations being removed, which is a change in behaviour for a point release.
- **`334aeadc5c` and `e17fc6283c`** (the example queries): they replace the JERM example queries,
  which 1.19 still needs.
- **Config defaults** (`cd7b338bc2`, `7da01532a4`, `01751845b4`): workflows and git enabled by
  default, and the Virtuoso ports. These aren't fixes.

## 2. Bringing the branch into `main`

This branch replaces JERM with Schema.org. The CSV file is reduced to three JSON-LD rows and
`mbox_sha1sum`. `to_rdf_graph` has the JERM steps commented out (`describe_type`,
`additional_triples`, `extended_metadata_triples`, `sample_metadata_triples`). The tests were
converted to Schema.org, or changed to expect no RDF for the ISA types. Merging it as it is would
remove the JERM RDF for every existing installation, and with it the RDF for Investigation, Study,
Assay, ObservationUnit, Model, Strain and CultureGrowthType, which have no Schema.org description.

The plan is to merge in stages. The changes that don't depend on the vocabulary go first. The
vocabulary is then chosen by configuration, as described in section 3.

### Stage 1: infrastructure that doesn't depend on the vocabulary (can go to `main` now)

These work with either vocabulary and can be reviewed as separate PRs. The named graphs, the atomic
updates, the regenerate all RDF button and the RDF queue reach `main` by merging `seek-1.19` (see
section 1).

- **When RDF is regenerated:** after membership changes (`51b8c76ef9`), and after annotation changes
  (`751807293b`), which matters once Schema.org is used.
- **Generating from JSON-LD:**
  - the CSV `j` kind (statements from a JSON-LD method);
  - `jsonld_statements`, with relative IRIs resolved against the item's URL (`741dd2c675`);
  - `http://schema.org/` normalised to `https://` (`7cc0a73c1f`);
  - the RO-Crate contexts preloaded (`c30d00ab4a`).

  On their own these don't change any output.
- **SPARQL UI:**
  - DESCRIBE fix;
  - columns per variable;
  - IRI/literal display;
  - tooltips;
  - GET submission;
  - the examples panel and dropdown, keeping the JERM queries for now.
- **Schema.org JSON-LD improvements:** these are useful on the page and in data dumps even without
  the knowledge graph:
  - the Publication decorator (`b0d7986a6f`);
  - workflow topics, disciplines and operations (`1edcf0aa88`);
  - the workflow diagram fixes (`ee0f533f70`).

### Stage 2: choose the vocabulary through the CSV mappings (see section 3)

- Restore `main`'s 80 JERM rows, tagged `jerm`. Tag this branch's rows `schema`.
- Bring the steps that aren't in the CSV into it as rows (`describe_type`, `additional_triples`,
  extended metadata, sample attributes, RightField), so that `to_rdf_graph` is driven entirely by the
  CSV.
- Add the `rdf_profiles` setting. Derive `rdf_capable_types` from the active profiles.
- **Default:** `jerm` for the next release, so existing installations see no change. `schema` and
  `jerm,schema` are opt-in from the admin page, followed by "regenerate all RDF".

### Stage 3: tests

- **Before converting:** the JERM tests on `main` (each type's `to_rdf`, the `rdf_test_cases`, the
  triple store tests, FAIR signposting) were converted on this branch. Bring back `main`'s versions
  to run under `jerm`, and keep this branch's versions to run under `schema`.
- **Test helper:** add a `with_rdf_profiles('schema') { ... }` helper, in the same style as
  `with_config_value`, and use it in the Schema.org tests.
- **Profile-independent tests:** run the RDF repository tests (named graphs, atomic updates,
  visibility changes) under both profiles, or against a fixed graph.
- **Skipped tests:** un-skip the extended metadata and sample attribute tests under `jerm`. Under
  `schema` they stay skipped until extended metadata becomes `additionalProperty` in the JSON-LD.

### Stage 4: example queries, docs and release

- **Example queries:** tag each query in `config/sparql_queries.yml` with its profile. Show only the
  queries for the active profiles.
- **Upgrade:** add a note to the upgrade instructions saying that changing `rdf_profiles` needs
  "regenerate all RDF". Optionally, add a `seek:upgrade` step that queues this when the setting
  changes.
- **Docs:** document the profiles, the CSV columns, and how a site can add or override rows.

### Still to do before Schema.org can be the default

- **Decorators for the ISA types:**
  - Investigation, Study and Assay as `Dataset` (or ISA-specific JSON-LD);
  - Model as `SoftwareSourceCode` or `Dataset`;
  - ObservationUnit;
  - Strain as `Taxon`, or a `BioChemEntity`.

  Until these exist, `jerm,schema` is the only setting that describes everything.
- **Extended metadata and sample attributes as `additionalProperty`/`PropertyValue`** in the
  JSON-LD. Samples already do this. Doing it for extended metadata would make it visible on the page
  as well.
- **Wrap RO-Crate generation in error handling,** and consider caching each frozen version's crate.
- **Rename `Workflow#ro_crate_metadata`** (for example to `ro_crate_metadata_jsonld`). It returns a
  JSON-LD string, but `Project#ro_crate_metadata` and `Person#ro_crate_metadata` return Hash
  fragments.
- **Remove leftovers:**
  - the commented-out code in `to_rdf_graph`;
  - the debugging `pp person.to_rdf` in `rdf_triple_store_test.rb`;
  - the `Test is missing assertions` warning from `test_send_schema_to_store`.

## 3. JERM, Schema.org, or both, through the CSV mappings

### The mapping file today

`lib/seek/rdf/rdf_mappings.csv` is read by `Seek::Rdf::CSVMappingsHandling`. Each row is
`class, method, property, kind, transformation, collection transformation`, where the kind is:

- `u`: a URI;
- `l`: a literal;
- `j` (added on this branch): the method returns JSON-LD, and every statement in it is added.

The `j` kind already makes the CSV a general way to plug in a source of statements. What's missing
is a way to choose which rows apply, and to move the remaining hard-coded steps into the CSV.

### Proposed changes

**1. Add a `profile` column as the first column.** Its values are `jerm`, `schema`, or `*` for rows
that apply to every profile.

```csv
profile,class,method,property,kind,transformation,collection transformation
jerm,*,title,RDF::Vocab::DC.title,l,,
jerm,*,creators,JERMVocab.hasCreator,u,item.class.name=='User' ? item.person : item,
jerm,Assay,assay_type_uri,JERMVocab.hasType,u,,
jerm,*,rdf_type_statements,nil,g,,
jerm,*,additional_triples,nil,g,,
jerm,*,extended_metadata_statements,nil,g,,
jerm,Sample,sample_metadata_statements,nil,g,,
jerm,DataFile,rightfield_statements,nil,g,,
schema,*,to_schema_ld,nil,j,,
schema,Workflow,ro_crate_metadata_jsonld,nil,j,,
schema,Institution,ror_json_ld,nil,j,,
*,Person,mbox_sha1sum,RDF::Vocab::FOAF.mbox_sha1sum,l,,
```

Separate files per profile (`rdf_mappings_jerm.csv`, `rdf_mappings_schema.csv`) would also work, and
would make it simpler for a site to override one of them. A column keeps everything in one place and
makes rows shared by both profiles explicit. Either way, the loader only needs to filter the rows.

**2. Add a `g` kind (graph)** for a method that returns an `RDF::Graph` or an array of statements.
`describe_type`, `additional_triples`, `extended_metadata_triples`, `sample_metadata_triples` and the
RightField RDF would become methods returning statements, listed in the CSV, rather than called from
`to_rdf_graph`. `to_rdf_graph` then becomes:

```ruby
def to_rdf_graph
  generate_from_csv_definitions(RDF::Graph.new)
end
```

**3. Add a `rdf_profiles` setting.** It goes in `config_setting_attributes.yml`, with a default of
`['jerm']`, and is shown on the admin page. `generate_from_csv_definitions` would skip rows whose
profile isn't active, and the parsed rows should be cached rather than re-reading the file for every
item.

**4. Derive `rdf_capable_types` from the active profiles:**

- **`jerm`:** `Seek::Rdf::JERMVocab.defined_types.keys`, which is how `main` defines it.
- **`schema`:** the Schema.org supported types that include `RdfGeneration`, which is how this
  branch defines it.
- **Both:** the union of the two.

`rdf_supported?`, the `.rdf` responses, FAIR signposting, "regenerate all", and the filter in
`generate_triples_for_csv_row` that drops related items without RDF all follow from this list, so
they adjust automatically. The guard on this branch that stops items without RDF from being queued
does too.

### How each setting behaves

| | `jerm` | `schema` | `jerm,schema` |
|---|---|---|---|
| Output | As on `main` today | As on this branch | Both sets of triples on the same item IRIs |
| Types with RDF | JERM types, including ISA, Model and Strain | Schema.org types, including Event, Presentation, Institution and Collection, but no ISA types | All of them |
| Example queries | JERM | Schema.org | Both |
| Size of the store | Baseline | Similar | About double for types in both |

### Things to check when running both

- **Same subjects:** both vocabularies describe the same item IRIs, so they combine cleanly in one
  graph. An item gets two `rdf:type`s (for example `jerm:Data` and `schema:Dataset`), which is valid
  and useful for queries in either vocabulary.
- **Duplicate descriptions of related items:** the Schema.org JSON-LD includes short descriptions of
  related items (`@type` and `name`). These overlap with those items' own statements, which is
  harmless because RDF graphs are sets. The per-item named graphs already deal with a statement that
  several items share. This was fixed in `bb9f93a956`, which removes only what no other item graph
  holds.
- **Linking between the vocabularies:** JERM rows link to related items with `u` rows, but only to
  types that are RDF-capable. With both profiles, JERM rows would start linking to Schema.org-only
  types, such as Event, Presentation and Institution. That is probably desirable, but it changes the
  JERM output for sites that turn on `schema`.
- **Changing the setting:** the item graphs record what each item contributed, so "regenerate all"
  replaces everything cleanly. The admin page should say that regeneration is needed when the setting
  changes.
- **Namespaces:** keep `https://schema.org/` as the namespace (already normalised). The JERM rows
  keep using `dcterms`, `foaf`, `sioc` and `jerm`, so the two vocabularies don't share predicates.

### Order of implementation

1. Add the `profile` column and the `g` kind, and tag every current row `schema`. No change in
   behaviour.
2. Turn the four hard-coded steps into `g` methods, and restore `main`'s JERM rows tagged `jerm`.
3. Add the `rdf_profiles` setting and the profile-based `rdf_capable_types`. Make the default `jerm`.
4. Bring back `main`'s JERM tests under `jerm`, and run the Schema.org tests under
   `with_rdf_profiles('schema')`. Add one test of `jerm,schema` that checks both kinds of type
   statement are present and that removing an item leaves nothing behind.
5. Tag the example queries with their profile, and show only those for the active profiles.
