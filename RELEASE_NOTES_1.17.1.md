# FAIRDOM-SEEK 1.17.1 Release Notes

## New Features

- **Discipline annotations for Workflows** — Workflows can now be annotated with discipline vocabulary terms (sourced from OpenAlex/EDAM Topics). Disciplines are auto-populated from the selected project and propagated on save (#2141)
- **ISA-JSON compliance filter** — Investigations, studies, and assays can now be filtered by ISA-JSON compliance status when browsing (#1798)
- **Group filter for ISA Sample Type templates** — Sample type templates can now be filtered by group when searching (#2322)
- **Units displayed in dynamic table** — Unit information is now shown in dynamic table column headers and data cells (#2358)

## Improvements

- **Publication author entry via comma-separated list** — Authors can now be typed or pasted as a comma-separated list; Select2 handles tokenisation automatically (#2330)
- **Publication author typeahead** — Improved query results with de-duplication, better incremental matching, and correct display of both registered and unregistered users (#815, #2336)
- **Registration page with third-party auth providers** — The registration UI has been restyled to place third-party auth options in tabs, fixing a broken layout when multiple providers are configured (#2355)
- **Licence short-form display** — Short-form licence names (e.g. CC-BY) are now shown alongside the full name; blank/notspecified values are suppressed (#2289)
- **ROR API updated to v2** — The Research Organization Registry integration now uses the v2 API (#2266)
- **Default permissions inherited at ISA study level** — Default project permissions are now correctly applied when creating studies (#2321)
- **Copyright addendum field** — The copyright addendum setting is now a textarea, supporting multi-line content (#2283)
- **RO-Crate spec adherence** — Added `datePublished` to RO-Crate root metadata, and corrected `conformsTo` to apply to the metadata file rather than the root entity (#2013, #2309)
- **Validate creators before minting DOI** — DOI minting is now blocked if no creators are present, with a clear error message (#2350)
- **Sample type button text** — Button labels in the sample type UI have been updated for clarity (#2312)
- **Observation Unit ordering** — Observation Unit now appears in the correct position in the asset sidebar, after Study (#2302)
- **Dynamic table fixes** — Multiple improvements: paste-from-clipboard removed, tooltips reset on each draw, timezone handling corrected for date display, and various small bugfixes (#2323, #2324, #2316, #2341)

## Bug Fixes

- **Deleted avatar causing 500 error** — Fixed a crash when a resource referenced a deleted avatar (#2281)
- **Assay streams not showing in related items** — Assay stream associations are now correctly displayed (#2242)
- **Error updating assay stream** — Fixed an error that occurred when updating assay stream attributes (#2306)
- **New controlled vocabulary button** — The button to create a new sample controlled vocabulary now works correctly in ISA-JSON compliant studies and assays (#2331)
- **Batch download missing selected samples** — Fixed batch download from the dynamic table not including all selected samples (#2347)
- **Wrong permissions check for batch update** — Corrected the authorisation check used by the batch update method (#2174)
- **Duplicate entry on publication list** — Fixed a doubled entry appearing in the publication association list (#411)
- **WorkflowSketch type removed from RO-Crate** — Removed the deprecated `WorkflowSketch` type which was no longer in the RO-Crate spec (#2309)

## Infrastructure & Dependencies

- Rails updated to 7.2.2.2
- Ruby updated to 3.3.9
- Rack security bumps (2.2.17 → 2.2.20)
- rexml security bump
- Ubuntu 20.04 removed from Ansible CI matrix
