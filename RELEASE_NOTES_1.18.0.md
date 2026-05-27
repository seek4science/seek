# FAIRDOM-SEEK 1.18.0 Release Notes

## New Features

- **Block local file uploads** — Admins can now configure SEEK to prevent users from uploading local files, requiring remote URLs instead. The UI updates dynamically to reflect the restriction (#2286)
- **DOI support for Presentations** — Presentations can now have DOIs minted and retracted, bringing them in line with other asset types (#2411)
- **Retract/delete resources with DOIs** — Resources with DOIs can now be deleted; the system handles DOI retraction as part of the process, storing the Datacite metadata and displaying a citation on the retraction record (#2497)
- **Temporary sharing links for ISA assets** — Investigations, Studies, Assays, and Observation Units can now be shared via temporary links without requiring a login (#758, #2554)
- **Register new Workflow version via RO-Crate upload** — A new version of an existing workflow can now be created by uploading an RO-Crate directly through the UI (#2453)
- **SOP type field** — SOPs now have a type field, exposed in both the UI and JSON API (#2478)
- **Event types and hybrid/online/offline location** — Events now support typed categories and a hybrid/online/offline location option (#2413)
- **Automatic publication type detection** — The publication type is automatically set when a DOI is queried during publication registration (#2410)
- **Free text allowed for controlled vocabulary Extended Metadata attributes** — Admins can configure Extended Metadata Type controlled vocabulary attributes to also accept free text (#2449)
- **Extended metadata in DataHub spreadsheet** — Extended metadata fields are now included in spreadsheet exports (#2475)
- **Input ISA tag** — A new "input" ISA tag is available, exposed through the API (#2244)
- **External search adapters toggleable via settings** — External search adapters (e.g. BioPortal) can now be individually enabled/disabled through the admin settings UI rather than via config files (#2374)
- **Option to disable SEEK local login** — Administrators can now disable the built-in username/password login to enforce SSO-only access (#2339)
- **Event end date auto-set** — When selecting an event start date/time, the end date is automatically set 1 hour later (#2412)

## Improvements

- **BibTeX import UI** — The BibTeX import interface has been clarified to make the two import options (file upload vs. paste) more obvious (#2315)
- **Bioschemas/schema.org enhancements for Workflows** — Added `creativeWorkStatus`, `contributor`, `citation`, `datePublished`, and other properties to the schema.org/Bioschemas output for workflows and other creative works (#2546)
- **RDF export for nested Extended Metadata attributes** — Nested (Linked) Extended Metadata attributes are now exported as blank nodes in the RDF output, with correct `RDF::XSD` type mappings (#2557)
- **Hyphen-proof search** — Search indexing and queries now handle punctuation such as hyphens correctly, so e.g. searching "UPC" finds results containing "UPC-1234" (#1823)
- **`registered_mode` exposed in Publications API** — The `registered_mode` field is now included in the Publications JSON API response (#2520)
- **Terms & Conditions checkbox placement** — The T&C checkbox now appears above the Register button on the registration form (#2528)
- **Units preserved from sample type templates** — Units defined in sample type templates are now correctly carried over when creating sample types (#2243)
- **Spreadsheet renamed for clarity** — The DataHub spreadsheet tab has been given a clearer name to avoid confusion (#2249)
- **Metadata license shown in footer** — The metadata license is now mentioned in the site footer; blank/nil/"notspecified" values are suppressed
- **Nested Extended Metadata attribute labels** — Label rendering for nested EMT attributes now prioritises the configured label over a generic humanised fallback (#2563)
- **Remove Skype name from user profile** — The Skype name field has been removed from user profiles (#2523)
- **Session table trimming in batches** — The sessions cleanup rake task now trims in batches to avoid timeouts on large tables

## Bug Fixes

- **PDF preview rendering** — Upgraded PDF.js from v0.7.55 to v2.16.105, fixing incomplete PDF rendering in the browser (#2343)
- **FDS import: required attribute matching** — Sample types and Extended Metadata types with required fields that are absent from the FDS import RDF are now correctly rejected as candidates, preventing incorrect type matches (#2527)
- **FDS import: core annotation handling** — Core RDF annotations (e.g. `rdf:type`, `rdfs:label`) are now ignored when matching sample types during FDS import (#2587)
- **FDS import: false duplicate sample type detection** — Fixed an incorrect "sample type already exists" error caused by matching solely on property count rather than property identity (#2589)
- **Registered sample attribute validation** — Sample attributes of type "Registered sample" no longer incorrectly turn red/invalid for IDs over 100 (#2514)
- **Batch delete nil error** — Fixed an error that could occur when batch-deleting assets with missing associations (#2459)
- **Spreadsheet download from default view** — Fixed downloading the DataHub spreadsheet when accessed from the default view (#2470)
- **Docker image missing LibreOffice** — Added missing LibreOffice dependency to the Docker image (#2460)
- **Notebook HTML generation Python version error** — Fixed an error in `generate_notebook_html` caused by an incorrect Python version (#2474)
- **XSS security fixes** — Multiple cross-site scripting vulnerabilities addressed

## Infrastructure & Dependencies

- Rails updated to 7.2.3.1
- MySQL in Docker Compose updated from 8.0 to 8.4
- Nokogiri security bump
- net-imap security bump
- nbconvert security bump
- jwt bumped to 3.2.0
- faraday bumped to 2.14.2
- SPDX licence list updated
- Example data seeds refactored into library classes
- Docker base images updated
