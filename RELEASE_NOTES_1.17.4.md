# FAIRDOM-SEEK 1.17.4 Release Notes

## Improvements

- **Institution typeahead includes department** — The institution typeahead now includes department names in its suggestions and search, making it easier to locate the right entry when institutions share similar names (#2519, #2515)
- **RO-Crate licence normalisation** — Licence values parsed from RO-Crate are now normalised to their SPDX identifier; licence objects (rather than plain strings) are handled correctly; and Workflow RO-Crate exports now use a URI for the licence field (#2512)
- **SPARQL and API endpoints require authentication** — Relevant endpoints that were previously publicly accessible have been placed behind authentication (#2518)

## Bug Fixes

- **Attribution ignored in DataFile creation wizard** — Fixed a bug where attributions set during the DataFile creation wizard were silently discarded on save (#2516, #2522)
- **Dynamic table hidden-sample handling** — Multiple fixes for the dynamic table when working with hidden samples: checkboxes are now correctly overwritten for hidden rows, the status column is non-editable, select-all works correctly, and deleting hidden or missing samples no longer causes errors
- **BioModels search error when filtering by year** — Fixed an error thrown by the BioModels external search when a year filter was applied, and corrected date handling in the API response (#2502, #2510)
- **Sample type template download permissions** — Fixed incorrect permission checks for downloading sample type templates; visible sample types now always have a downloadable template, and anonymous users cannot download (#2505, #2506)
- **HTML tags indexed by Solr** — HTML tags in content were being passed raw to the Solr index; the plain-text pipeline now fully strips HTML instead of escaping it (#2501)
- **Batch delete nil error** — Fixed an undefined-method error that could occur when batch-deleting assets with missing associations (#2503)
- **Spreadsheet download fix** — Addressed a remaining edge case preventing spreadsheet download (#2492)

## Infrastructure & Dependencies

- Rack security bump (2.2.20 → 2.2.22)
- API example files updated
