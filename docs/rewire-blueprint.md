---
title: "WorkflowHub and RO-Crate: publishing reproducible workflows"
search_exclude: false
description: "How WorkflowHub, built on FAIRDOM-SEEK, packages, registers and serves computational workflows as Workflow RO-Crates, and a blueprint for extending it with the RO-Crate profiles developed in REWIRE."
contributors: []
page_id: workflowhub_ro_crate
type: research_software_story
---

<!--
Draft 0 of a research software story in the RSQKit template
(https://everse.software/RSQKit/), written as a candidate blueprint for the REWIRE Knowledge Hub
(https://rewire-hub.eu/knowledge-hub, task T1.2 BLUEPRINTS).
It was drafted from the FAIRDOM-SEEK source code (see ro-crate.md in this folder), the REWIRE project page
(https://esciencelab.org.uk/projects/rewire/) and public WorkflowHub documentation.
Nothing here has been confirmed by the WorkflowHub team yet; open questions are collected at the end.
One sentence per line is deliberate (RSQKit source convention).
-->

## The Problem
### Computational workflows need to be published as complete, machine-actionable objects, not as loose files

A workflow file on its own is rarely enough to reuse or reproduce an analysis.
Users also need to know who wrote it, under what licence, which language and version it is written in, what its inputs and outputs are, how it was tested, and where its supporting files are.
Before a common packaging format, this information was scattered across code repositories, papers and registry forms, and was hard for machines to find or for other systems to exchange.

WorkflowHub addresses this by treating each workflow version as a [Workflow RO-Crate](https://w3id.org/workflowhub/workflow-ro-crate/1.0): a zip archive holding the workflow, its diagram, an optional abstract [CWL](https://www.commonwl.org/) description, test definitions and any other files, described by a JSON-LD metadata file.
The crate is both how a workflow arrives in WorkflowHub and how it leaves it.

[REWIRE](https://esciencelab.org.uk/projects/rewire/) widens the problem from publishing a workflow to publishing the whole reproducible research process.
REWIRE names RO-Crate as its publishing intervention and "an integration layer" between planning (machine-actionable Reproducibility Management Plans), execution ([GNU Guix](https://guix.gnu.org/) computational environments) and publication.
In the UK, the [BioFAIR](https://esciencelab.org.uk/projects/biofair/) Methods Commons, funded by UKRI from July 2026 and led by the University of Manchester with the Earlham Institute and Seqera, aims "to establish a world-leading, standards-based national infrastructure for FAIR computational workflows in the UK life sciences", "making it easy to find high-quality workflows, run them at scale and share them with full provenance".
It names WorkflowHub as the single access point for workflows, a curated "BioFAIR Workflow Collection", a "Shared Project Space" that records runs as Workflow Run RO-Crates and catalogues them with FAIRDOM-SEEK, a "Workflow Observatory" for trust and quality, and RO-Crate and GA4GH as its API standards.
This story records where WorkflowHub stands today and what it would take for it to carry the RO-Crate profiles REWIRE develops and the run provenance the Methods Commons depends on.

Scope and boundaries:

- The story covers RO-Crate support in the [FAIRDOM-SEEK](https://github.com/seek4science/seek) code base as it runs [WorkflowHub](https://workflowhub.eu/).
- It does not cover the wider SEEK features for ISA (Investigation, Study, Assay) data management, which do not use RO-Crate today.

## User Community
### Workflow authors, research infrastructures and tools that consume workflows

WorkflowHub's users are researchers who publish computational workflows, and researchers who look for workflows to reuse.
The supported workflow languages seeded with the software are Common Workflow Language, Galaxy, KNIME, Nextflow and Snakemake, so its users come from the communities around those systems.
A large share of the traffic is from machines rather than people: continuous-integration pipelines that submit new workflow versions, workflow systems such as [Galaxy](https://galaxyproject.org/) that import workflows through the [GA4GH TRS API](https://ga4gh.github.io/tool-registry-service-schemas/), [LifeMonitor](https://lifemonitor.eu/) which runs workflow tests, and harvesters that follow [FAIR Signposting](https://signposting.org/FAIR/) links.

Within REWIRE, the pilots in biodiversity, life sciences, robotics, biomedical artificial intelligence, publishing and information technology are potential new user communities.
Which of these pilots will use WorkflowHub is not yet decided.

## Technical Aspects

WorkflowHub is a deployment of FAIRDOM-SEEK, a web platform and registry that sits in the research software infrastructure tier of the [RSQKit three-tier view](https://everse.software/RSQKit/three_tier_view).
SEEK is a Ruby on Rails application (Rails 7.2, Ruby 3.3), developed since 2008, and currently at version 1.20 on its main branch.
The same code base also runs [FAIRDOMHub](https://fairdomhub.org/) and other SEEK instances; WorkflowHub is distinguished only by configuration, with workflows, git storage, the TRS API and FAIR Signposting switched on.

RO-Crate support works in four steps:

- **Import.** A crate is uploaded through the web form, the JSON API, or a `submit` endpoint designed for continuous integration, which matches an existing workflow by the crate's source URL and version.
  The crate is unpacked into a git repository, one git version per workflow version.
- **Metadata extraction.** Title, description, keywords, licence and creators are read from the crate's root entity; the workflow type from the main workflow's `programmingLanguage`; inputs, outputs and steps from the workflow file or its abstract CWL; and fallbacks from `README.md`, `CITATION.cff` and licence files.
- **Export.** For workflows not uploaded as full crates, SEEK generates a Workflow RO-Crate, merging in its own [Bioschemas](https://bioschemas.org/) description of the workflow.
  Uploaded crates are served as uploaded.
- **Serving.** Each version's crate is available as a zip and as bare metadata, advertised through FAIR Signposting, and used as the file source for the TRS API.

The main technical constraints are that crates must stay valid as they pass through SEEK, that an uploaded crate is an authored artefact which SEEK should not silently alter, and that each crate must be versioned in step with the workflow it describes.

### Libraries and Systems

RO-Crate handling is built on the [`ro-crate` Ruby gem](https://github.com/ResearchObject/ro-crate-ruby) (version 0.7.0, which writes RO-Crate 1.3 by default and reads 1.0 to 1.3), extended inside SEEK with Workflow RO-Crate classes for the main workflow, its diagram and its CWL description.
Other dependencies on the RO-Crate path include [licensee](https://github.com/licensee/licensee) for detecting licence files, the [json-ld](https://github.com/ruby-rdf/json-ld) gem for merging Bioschemas metadata, and git for storing crate contents.
The application as a whole depends on MySQL, Apache Solr for search, Redis for caching and sessions, and Solid Queue for background jobs.

Standards and formats a contributor needs to know:

- [RO-Crate](https://w3id.org/ro/crate) and the [Workflow RO-Crate profile](https://about.workflowhub.eu/Workflow-RO-Crate/).
- The [Workflow Testing RO-Crate](https://lifemonitor.eu/workflow_testing_ro_crate) profile, used to detect test suites.
- Bioschemas [ComputationalWorkflow](https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/) and [FormalParameter](https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/) profiles.
- GA4GH TRS v2, FAIR Signposting, and the [Citation File Format](https://citation-file-format.github.io/).

## Software Practices
### Open development with automated tests and continuous integration

SEEK is developed in the open on GitHub, with feature branches merged into `main` and release branches such as `seek-1.19`.
Automated tests use Minitest for unit, functional and integration tests and RSpec for a smaller set of specifications, and run on GitHub Actions.
The RO-Crate code has its own fixtures: two dozen example crates covering edge cases such as missing main workflows, remote files, different licence forms, creators with ORCIDs, CFF files and test suites.
Code style is checked with RuboCop.

Experimental work is done on long-running branches with written evaluations.
For example, the `schema-knowledge-graph-messing` branch, which adds RO-Crate metadata to a Schema.org knowledge graph, carries its own evaluation and a staged plan for merging.

## Developer Community
### A small core team with contributions from the WorkflowHub and FAIRDOM communities

The git history shows 14 distinct author names over the past year.
New contributors start from the developer instructions in the repository (`AGENTS.md`), the [contributing guide](https://docs.seek4science.org/tech/contributing.html), and the Docker Compose set-up, which starts SEEK with its database, search and worker processes.
For RO-Crate work, the developer map in [`ro-crate.md`](ro-crate.md) lists the code involved, with links to each part.

The main obstacle for newcomers is the size of the code base: RO-Crate handling is spread across controllers, models, form objects, extractors and gem extensions, and its behaviour depends on several site settings.

## Tools
### Continuous integration, containers and automated deployment

GitHub Actions runs the test suite, builds Docker images and checks the Ansible installation; a further workflow manages stale issues.
SEEK is packaged as a Docker image with Compose files for the full stack, including an optional Virtuoso triple store.
Within REWIRE, [rocrate-validator](https://github.com/crs4/rocrate-validator) is a natural addition to this tool chain, so that crates are checked against their profiles both in SEEK's own tests and on upload.

## FAIR & Open
### Workflows are published as self-describing, identifiable and harvestable packages

- **Findable.** Each workflow version has a stable URL and can be given a DOI, which the generated crate uses as its `identifier`. Landing pages carry Bioschemas JSON-LD and FAIR Signposting links, including a typed link to the crate (`profile="https://w3id.org/ro/crate"`).
- **Accessible.** Crates are downloadable over HTTP as zip files or as bare metadata, through the web interface, the JSON API and the GA4GH TRS API, subject to each workflow's sharing policy.
- **Interoperable.** Metadata uses RO-Crate, Schema.org and Bioschemas; workflow languages are described as `ComputerLanguage` entities; the TRS API lets workflow systems import workflows directly.
- **Reusable.** Licences are recorded as URLs, creators as persons with ORCIDs where known, and the source repository as `isBasedOn`.
- **Open software.** SEEK itself is released under the [BSD 3-clause licence](../BSD-LICENSE) and developed in a public repository.

## Documentation
### User, developer and administrator documentation lives on three sites

The main entry points are [about.workflowhub.eu](https://about.workflowhub.eu/) for WorkflowHub users and API clients (including the Workflow RO-Crate profile and the RO-Crate submission API), [docs.seek4science.org](https://docs.seek4science.org/) for SEEK users and administrators, and the API reference served by each instance at `/api`.
Developer documentation for RO-Crate support is in [`ro-crate.md`](ro-crate.md).

Known gaps:

- The OpenAPI reference does not list the RO-Crate endpoints, and the continuous-integration `submit` endpoint is not documented.
- The SEEK administration guide does not cover enabling workflows or RO-Crate.
- Some upload pages still link to an outdated description of the format.
- A proposal for updating the WorkflowHub developer pages is in [`workflowhub-developer-pages-proposal.md`](workflowhub-developer-pages-proposal.md).

## Sustainability
### A shared code base maintained across several services

WorkflowHub is supported long-term by ELIXIR and the Australian BioCommons and is a service of the European Open Science Cloud; if it reaches end of service, its published contributions and metadata are to be archived as RO-Crates in Zenodo [Gustafsson 2025].
That plan relies on RO-Crate export for everything WorkflowHub holds, which the code provides today only for workflows.
Because WorkflowHub, FAIRDOMHub and other SEEK instances share one code base, maintenance effort on the core platform benefits all of them.
The RO-Crate support depends on the externally maintained `ro-crate` Ruby gem and on profiles governed by the RO-Crate and WorkflowHub communities.
REWIRE runs from September 2026 to August 2029, and the University of Manchester leads REWIRE task T2.3 on RO-Crate profiles, which gives a route for keeping WorkflowHub aligned with new profiles during that period.
The BioFAIR Methods Commons invests up to £4 million over an initial two years (July 2026 to July 2028), with an expected extension to June 2029 and beyond, and makes WorkflowHub part of a UK national infrastructure.
The two projects overlap in the same need: RO-Crate profiles defined in REWIRE are what the Methods Commons would use for run provenance in practice.

The main risks are drift between the profiles WorkflowHub declares and the current versions of those profiles, and features that are only switched on in WorkflowHub's configuration and so are less exercised by other SEEK deployments.

## References

The story builds on the following material.

- FAIRDOM-SEEK source code: <https://github.com/seek4science/seek>; developer map of RO-Crate support: [`ro-crate.md`](ro-crate.md).
- Wolstencroft K. *et al.* (2015). SEEK: a systems biology data and model management platform. *BMC Systems Biology* 9:33. <https://doi.org/10.1186/s12918-015-0174-y>
- [Goble 2023] Goble C, Bacall F, Soiland-Reyes S, Owen S, Eguinoa I, Droesbeke B, Ménager H, Rodriguez-Navas L, Fernández JM, Grüning B, Leo S, Pireddu L, Crusoe M, Gustafsson J, Capella-Gutierrez S, Coppens F (2023). The EOSC-Life Workflow Collaboratory for the Life Sciences. *Proceedings of the Conference on Research Data Infrastructure* 1. <https://doi.org/10.52825/cordi.v1i.352>
- [Gustafsson 2025] Gustafsson OJR, Wilkinson SR, Bacall F, Soiland-Reyes S, Leo S, Pireddu L, Owen S, Juty N, Fernández JM, Brown T, Ménager H, Grüning B, Capella-Gutierrez S, Coppens F, Goble C (2025). WorkflowHub: a registry for computational workflows. *Scientific Data* 12, 837. <https://doi.org/10.1038/s41597-025-04786-3>
- [Wilkinson 2025] Wilkinson SR, Aloqalaa M, Belhajjame K, Crusoe MR, de Paula Kinoshita B, Gadelha L, Garijo D, Gustafsson OJR, Juty N, Kanwal S, Khan FZ, Köster J, Peters-von Gehlen K, Pouchard L, Rannow RK, Soiland-Reyes S, Soranzo N, Sufi S, Sun Z, Vilne B, Wouters MA, Yuen D, Goble C (2025). Applying the FAIR Principles to computational workflows. *Scientific Data* 12, 328. <https://doi.org/10.1038/s41597-025-04451-9>
- [Wilkinson 2026] Wilkinson SR, Gustafsson J, Bacall F, Belhajjame K, Capella S, Fernandez Gonzalez JM, Fosso Tande J, Gadelha L, Garijo D, Grubel P, Grüning B, Khan FZ, Kanwal S, Leo S, Owen S, Pireddu L, Pouchard L, Rodríguez-Navas L, Serrano-Solano B, Soiland-Reyes S, Vilne B, Williams A, Wouters MA, Coppens F, Goble C (2026). An ecosystem of services for FAIR computational workflows. In: Leser U, Hilbrich M, Wilkinson SR, Ferreira da Silva R (eds), *Workflow systems for large-scale scientific data analysis*, chapter 4, pp. 113–145. Berlin Universities Publishing. <https://doi.org/10.14279/depositonce-25818> ([PDF](https://depositonce.tu-berlin.de/bitstreams/eca0777c-d7b1-409a-a214-1bb4fe210e04/download))
- [KG 2026] Chadwick E, Woolland O, Hambley A, Savchenko V, Soiland-Reyes S (2026). WorkflowHub Knowledge Graph, version 2026-10-17. Zenodo. <https://doi.org/10.5281/zenodo.23691282>
- BioFAIR Methods Commons: <https://esciencelab.org.uk/projects/biofair/>, <https://biofair.uk/updates/2026/biofair-announces-4-million-investment-to-create-a-methods-commons-led-by-the-university-of-manchester/>.
- Soiland-Reyes S *et al.* (2022). Packaging research artefacts with RO-Crate. *Data Science* 5(2). <https://doi.org/10.3233/DS-210053>
- How the papers compare with the code: [`ro-crate.md`](ro-crate.md#workflow-ro-crate-in-the-literature).
- RO-Crate specification: <https://w3id.org/ro/crate>; Workflow RO-Crate profile: <https://about.workflowhub.eu/Workflow-RO-Crate/>; Workflow Run Crate profiles: <https://www.researchobject.org/workflow-run-crate/>.
- REWIRE project: <https://esciencelab.org.uk/projects/rewire/>, <https://rewire-hub.eu/>, CORDIS <https://doi.org/10.3030/101287431>.
- GA4GH TRS: <https://ga4gh.github.io/tool-registry-service-schemas/>; FAIR Signposting: <https://signposting.org/FAIR/>; Bioschemas: <https://bioschemas.org/>.
- RSQKit: <https://everse.software/RSQKit/>.

## Appendix: Lessons

SEEK has followed the Research Object idea through three formats.
Since 2012 it has published its own JERM RDF for ISA content, served as RDF and, since 2025, through a SPARQL page.
Since 2015 it has packaged ISA snapshots as Research Object Bundles, with JERM RDF inside, DOIs and Zenodo deposit.
Since 2019 it has packaged workflows as RO-Crates, which replaced Research Object Bundles in the wider community.
The result is that SEEK's two halves use different formats: ISA content has RDF but no RO-Crate, and workflows have RO-Crate but no RDF.
Schema.org JSON-LD, already shared by both, is the likely common ground; the experimental knowledge-graph branch builds on it.

Keeping the crate as the unit of import, storage and export has made WorkflowHub's integrations simple to build: TRS, Signposting and LifeMonitor all reuse the same package.
Declaring profile versions in code needs active upkeep: generated crates currently declare RO-Crate 1.3 together with Workflow RO-Crate 1.0, which is a profile of RO-Crate 1.1, while the profile itself has moved on to 1.1.
Whether a registry may rewrite an uploaded crate is a policy question as much as a technical one, and the experimental regeneration work shows that the answer needs to be explicit, tested on the real storage path, and visible to users.

## Appendix: Impact

In 2023 WorkflowHub had over 380 workflows from over 170 workflow teams, with adoption already extending beyond the life sciences to biodiversity, astronomy, astrophysics and climate change [Goble 2023].
By the submission of the WorkflowHub paper it had 860 workflows and 958 users from 266 organisations in 36 countries or locations [Gustafsson 2025].
Workflow RO-Crate is the exchange format between WorkflowHub and execution platforms such as Galaxy, Sapporo and WfExS, testing services such as LifeMonitor, and archives such as Zenodo [Goble 2023; Gustafsson 2025].
In the wider ecosystem, Galaxy, Snakemake, CWL and Nextflow support the metadata framework natively, including Workflow Run Crates for provenance, and run records are deposited in data repositories as Workflow Run RO-Crates and "occasionally registered in WorkflowHub to be published to support publications" [Wilkinson 2026].
The FAIR principles for computational workflows use WorkflowHub's RO-Crates as their worked example of a FAIR workflow specification, and a Provenance Run Crate as their example of a FAIR workflow run [Wilkinson 2025].

In the WorkflowHub Knowledge Graph of October 2026, 713 of 1,581 workflows (45%) came with an RO-Crate supplied by their source rather than generated by WorkflowHub [KG 2026].
The main suppliers are the Galaxy Training Network (393), Galaxy's Intergalactic Workflow Commission (118), nf-core (70), the COMPSs runtime (68, as Workflow and Provenance Run Crates), oxo-flow (23) and Autosubmit (10, as Workflow Run Crates).
The analysis is in [`ro-crate.md`](ro-crate.md#who-supplies-ro-crate-metadata-on-workflowhubeu).

<!-- TODO: crate downloads and TRS imports. -->

## Appendix: Future Directions — the REWIRE blueprint

This appendix maps the gaps in WorkflowHub's RO-Crate support to REWIRE's work packages and to the BioFAIR Methods Commons capabilities, as a plan rather than a commitment.

| Step | What | REWIRE link | BioFAIR Methods Commons |
|---|---|---|---|
| 1 | Declare the current Workflow RO-Crate profile (1.1) and a consistent RO-Crate version in generated crates. | T2.3 RO-Crate Profiles | API standards (RO-Crate) |
| 2 | Validate uploads with rocrate-validator against the profiles a crate declares, and show the result to the submitter. | T2.3, T2.5 PLAYBOOK | Workflow Observatory |
| 3 | Recognise Process, Workflow and Provenance Run Crates. They can already be registered, and are served as uploaded [Gustafsson 2025], but SEEK does not read them: show recorded runs, make them searchable, and link each run to the workflow version it executed. | T2.3 (Process and Workflow Run profiles) | Shared Project Space (Workflow Run RO-Crate provenance) |
| 4 | Accept and link machine-actionable plans (for example from [ARGOS](https://argos.openaire.eu/)) and environment definitions (for example GNU Guix manifests) inside crates, so a crate can connect plan, environment, workflow and runs. | T2.2 Guix, T2.4 Cross-Intervention Integration | Containerised workflows on HPC; Concierge Service |
| 5 | Decide and document whether WorkflowHub may add its own metadata to uploaded crates, building on the experimental regeneration settings, without losing the uploaded original. | T2.3, T1.4 Policy | BioFAIR Workflow Collection (endorsed workflows) |
| 6 | Document the RO-Crate endpoints in the OpenAPI reference, and the submission and validation steps as a REWIRE playbook. | T2.5 PLAYBOOK, T1.2 BLUEPRINTS | Onboarding playbooks; standardised APIs |
| 7 | Move SEEK's ISA snapshots from Research Object Bundles to RO-Crate (for example the ISA RO-Crate profile), so that SEEK has one packaging format and ISA studies can link to the workflows and runs that produced their data. | T2.3, T2.4 | BioFAIR DataHub (ISA catalogue) linking to workflow runs |
| 8 | Offer WorkflowHub as a publishing target in pilots and exemplar use cases that use workflows, and feed their experience back into this blueprint. | WP3 pilots (T3.3 Pilot Group B) | Nine Exemplar Use Cases |

## Open TODOs

- **Contributors:** confirm the names for the `contributors` front matter and add them to RSQKit's `_data/CONTRIBUTORS.yml`.
- **User Community:** confirm which REWIRE pilots will use WorkflowHub, and add user numbers or examples of communities.
- **Developer Community:** confirm how development of SEEK and WorkflowHub is organised and governed, and who maintains the RO-Crate support.
- **Sustainability:** confirm current funding for SEEK development beyond REWIRE, and plans beyond 2029.
- **References:** confirm the full author list for the RO-Crate paper (taken from a reference list, not the paper itself).
- **Impact appendix:** add current figures from workflowhub.eu; the cited figures are from 2023 and the 2025 paper's submission.
- **BioFAIR:** confirm how the Shared Project Space will store and catalogue Workflow Run RO-Crates in SEEK, and which Methods Commons capabilities the blueprint should commit to.
- **Future Directions:** confirm REWIRE's names for the "Recuperative" and machine-actionable DMP RO-Crate profiles, and whether WorkflowHub should support them.
- **Export:** add the page to `_data/sidebars/main.yml` if this is submitted to RSQKit, or agree the format for the REWIRE Knowledge Hub.
