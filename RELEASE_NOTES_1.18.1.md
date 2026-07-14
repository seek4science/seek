# FAIRDOM-SEEK 1.18.1 Release Notes

## Improvements

- **CFF file validated before bibtex conversion** — CITATION.cff files are now validated before attempting to convert to BibTeX, giving a clear error rather than a cryptic failure (#2640)
- **Database indexes on sample foreign keys** — Added indexes on `samples.originating_data_file_id` and `samples.sample_type_id` for improved query performance (#2637)
- **Git file upload error handling** — Better validation and error handling when adding files to Git-backed workflow versions, including a check that either a URL or file data is provided (#2642)
- **RO-Crate 1.3 spec support** — The `ro-crate` gem has been updated to support the RO-Crate 1.3 specification
- **Units for global ISA templates** — Units can now be configured on attributes in global ISA sample type templates (#2622)
- **Unit locking in sample types** — Units on sample type attributes can now be locked down to prevent users from changing them (#2489)
- **Fail fast on database unavailability at startup** — SEEK now raises an error immediately if the database is unreachable when configuration loads, rather than silently falling back to defaults and causing confusing behaviour (#2667)

## Bug Fixes

- **Git ImmutableVersionException on new workflow version** — Fixed an error that prevented new versions of a workflow from being submitted due to an immutable version lock being applied prematurely (#2626)
- **SlideShare renderer errors** — Fixed a JSON parse error and a nil return from the SlideShare renderer that could cause a NoMethodError (#2629)
- **Search adaptor appearing enabled after being disabled** — Fixed the features enabled page incorrectly showing a search adaptor as active after it had been disabled (#2628)
- **EST applied to assay creation behaving inconsistently in DataHub** — Fixed differing behaviour when applying an extended study template during assay creation (#2566)
- **LinkingSamplesUpdateJob crash** — Fixed a crash in the background job that updates linked samples when an attribute is singly-linked (#2652)
- **Non-UTF-8 CSV files causing error when exploring** — CSV files with non-UTF-8 encodings are now handled gracefully instead of raising an unhandled error (#2669)
- **Nil error with no authors in CITATION.cff** — Fixed a crash when a CITATION.cff file contains no authors (#2639)

## Infrastructure & Dependencies

- concurrent-ruby security bump
