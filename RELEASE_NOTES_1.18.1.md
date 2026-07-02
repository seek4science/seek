# FAIRDOM-SEEK 1.18.1 Release Notes

## Improvements

- **CFF file validated before bibtex conversion** — CITATION.cff files are now validated before attempting to convert to BibTeX, giving a clear error rather than a cryptic failure (#2640)
- **Database indexes on sample foreign keys** — Added indexes on `samples.originating_data_file_id` and `samples.sample_type_id` for improved query performance (#2637)
- **Git file upload error handling** — Better validation and error handling when adding files to Git-backed workflow versions, including a check that either a URL or file data is provided (#2642)
- **RO-Crate 1.3 spec support** — The `ro-crate` gem has been updated to support the RO-Crate 1.3 specification

## Bug Fixes

- **Git ImmutableVersionException on new workflow version** — Fixed an error that prevented new versions of a workflow from being submitted due to an immutable version lock being applied prematurely (#2626)
- **SlideShare renderer errors** — Fixed a JSON parse error and a nil return from the SlideShare renderer that could cause a NoMethodError (#2629)
- **Search adaptor appearing enabled after being disabled** — Fixed the features enabled page incorrectly showing a search adaptor as active after it had been disabled (#2628)
- **EST applied to assay creation behaving inconsistently in DataHub** — Fixed differing behaviour when applying an extended study template during assay creation (#2566)

## Infrastructure & Dependencies

- concurrent-ruby security bump
