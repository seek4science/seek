# FAIRDOM-SEEK 1.17.2 Release Notes

## New Features

- **Comprehensive SPARQL query interface** — A new interactive SPARQL query interface lets users run queries against the triple store directly from the browser, with syntax-highlighted results, format selection (XML/JSON), example queries, a copy-to-URL button for sharing queries, and a clear-results button (#2378, #2303)
- **Publication types aligned with DataCite schema** — The publication type list has been overhauled to align with the DataCite Metadata Schema, adding new types such as "Project Deliverable" and "Software" (resolving long-standing support for software citations via BibTeX); legacy types are migrated automatically (#2408, #2409, #407)
- **ML/AI model types and execution environments** — Model types now include ML/AI categories; model formats have standardized terminology; and supported execution environments have been expanded to include Python, R, Docker, Julia, Jupyter Notebook, and common ML frameworks (#2370, #2371, #2372, #2291, #2292, #2293)
- **ROR fetch button in Guided Create** — The button to look up institutions via the Research Organization Registry (ROR) is now available in the guided project/institution creation flow (#2426, #2421)
- **PubMed configuration status in UI** — The UI now shows a clear message when PubMed is not configured and prevents its use to avoid confusing errors; the unused `crossref_api_email` setting has been removed (#2433, #2431)

## Improvements

- **DOI parser refactored** — The external `doi_query_tool` gem has been removed and replaced with internal Crossref and Datacite parsers, centralising shared logic (HTTP requests, JSON parsing, author/editor extraction) and providing more informative error messages
- **Schema.org / Bioschemas enhancements** — The `.jsonld` endpoint is now available for all resource types that generate schema.org/Bioschemas output; DOI and ROR identifiers are included in the schema.org representation; Institution now exposes its ROR URL as an identifier; SOP gains a basic `LabProtocol` type (#2386, #2387, #2384, #2379)
- **Publication abstract formatting** — Leading and trailing whitespace is now stripped from publication abstracts on import (#2416, #2404)
- **ReindexAllJob batchsize configurable** — The batch size used by the background reindex-all job is now configurable and defaults to 50 to avoid timeouts on large instances (#2441, #2440)
- **Permission overwrite warning** — A warning is now shown when accepting default project permissions would overwrite existing permissions on a resource; the permission-propagation checkbox is hidden when it is not applicable (#2365, #849)
- **Spreadsheet download authorization** — Attempting to download the DataHub spreadsheet without the required permissions now aborts with a proper error rather than silently downloading an empty file (#2407, #2247)
- **Correct redirections in ISA-JSON compliant resources** — Several incorrect redirections after managing ISA-JSON compliant resources (study samples table, assay sample types, manage page cancel) have been corrected (#2427, #2428)

## Bug Fixes

- **500 error on invalid citation style** — An invalid citation style parameter no longer causes a server error; it is now stored safely and handled gracefully (#2446)
- **SPARQL copied URL returning 404** — Fixed a bug where using the copy-to-URL feature on a SPARQL query produced a URL that returned a 404 (#2434, #2435)
- **NoMethod error in dynamic data method** — Fixed a NoMethod error that could occur in the dynamic data table method (#2438, #2437)
- **Sample type download endpoint errors** — Fixed errors raised by the sample type download endpoint (#2377, #2376)
- **Inaccurate warning when registering publication via DOI** — Removed a misleading warning about abstracts not being available for DOIs; a message is now shown only if the abstract is genuinely missing (#2423)
- **RO-Crate author with remote @id** — Added a guard against cases where an RO-Crate author `@id` is a remote reference not described in the metadata file

## Infrastructure & Dependencies

- Ruby updated to 3.3.10
- `doi_query_tool` gem removed; DOI parsing is now handled by internal Crossref/Datacite parsers
- Virtuoso test image locked to 7.2.15 for reproducible CI
- RDF graph configuration made more flexible within Docker containers (#2367)
- Example data seeds expanded with more comprehensive dataset (organisms, strains, observation units, SOPs, publications, ROR-identified institutions)
