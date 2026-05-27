# FAIRDOM-SEEK 1.17.3 Release Notes

## Bug Fixes

- **Content blob file upload via API** — Fixed an error when uploading file content for a data file via the API; the chunk size has been reduced to 1 MB and the temporary IO object is now always handled as an IO stream (#2477, #2486)
- **Spreadsheet download from default view** — Fixed an error that prevented downloading the DataHub spreadsheet when accessed from the default asset view (#2469)
- **PubMed export error handling** — Export operations that fail because the PubMed email address is not configured now report a clear error rather than raising an unhandled RuntimeError (#2464, #2481, #2473)

## Infrastructure & Dependencies

- httparty bumped from 0.22.0 to 0.24.0
- uri security bump (1.0.3 → 1.0.4)
- Copyright year in footer updated to 2026
