---
title: Definitions
layout: page
---

# FAIRDOM-SEEK definitions
Definition of terms used in FAIRDOM-SEEK.

## Profile
A profile corresponds to information in SEEK about a person that can be a registered user (with an account) or a non-registered user (without an account).
### People or Person
Existing profile(s) in SEEK.
### Account
An account identifies a registered user.

### Identity
Each different way you login is considered an “identity”. Multiple identities can be connected to one SEEK account.
* LS Login: Life Science Login (previous ELIXIR-AAI)
* GitHub

### Institution
Where a registered user is employed or work or a registered user's affiliation for a specific Project.

### My favourites
Where favourite searches are saved after dragging the icon over to your Favourites.

### My Items
It shows all items related to your profile.

### My projects
List of all Projects that the registered user administers and is a member of.

### Provide feedback
Form to provide feedback (also anonymously) about the platform to the provider team.

## Directory
Alias for Yellow pages. Section listing registered people, institutions, projects and programmes.

## Yellow pages
Section listing registered people, institutions, projects and programmes.

### Programme
Programme is an umbrella to group one or more Projects (associated Projects).
* Web page: link to an online page related to the Programme.

### Project
Any element in SEEK must be associated to a Project (except for Programme), directly or indirectly.
The purpose of the Project level can be decided by the user.

The utilization of the Project feature in SEEK depends on the users and the organization of their research. Users have the flexibility to determine the purpose of the Project level based on their needs and the way their research is organized.

### Funding codes
Codes of funded grants related to the Project or Programme.
### Funding details
Any detail about funded grants related to the Project or Programme.
### Role
A number of specialist roles to which users can be assigned.
* Programme administrator: manage and administer the Programme.
* Project administrator: manage and administer the Project and its members.
* Asset housekeeper: manage assets belonging to other people in the project who have been flagged as having become inactive in the project.
* Asset gatekeeper: control whether assets within the project are made public.
* PALs: people acting as liaisons between the development team of this software and the users of this software.

### Site managed programme
Programme administered by the instance administrators (or platform administrators).
### Space
Alias for Programme. An umbrella to group one or more Teams.
### Team
Alias for Project.
<!--From info icon: research activities conducted by a group of one or more people. From user guide: represents a group of one or more people collaborating together on a particular activity.-->

## Experiments
Scientific procedures undertaken to make a discovery, test a hypothesis or demonstrate a fact.
### Assay
<!--From user guide:-->An assay is in general an experiment that converts either a material or data sample, into a new material or data sample, via a protocol. 

<!--From info icon:-->An Assay is in general the application of a process (SOP) that converts an input material or data (incoming samples) into a new material or data (outgoing samples). An Assay must belong to one Study.
### Assay design
Tab to interact with protocols and samples in an ISA-JSON compliant experiment.
### Design Assay
Design and create an Assay according to the [ISA metadata framework specifications](https://isa-specs.readthedocs.io/en/latest/isamodel.html#assay) (ISA Assay). An ISA Assay corresponds to one "process node" of the ISA metadata framework.
### Design Assay stream
An assay stream constitutes a structured sequence of sequential assays, interconnected through the flow of samples. Within an assay stream, the sample output of one assay serves as the input for the subsequent one. Each assay stream aligns with a single Assay in the ISA metadata framework. It is typically associated with one specific technology or technique, such as Metabolomics or Sequencing.
### Design Investigation
Design and create an Investigation according to the [ISA metadata framework specifications](https://isa-specs.readthedocs.io/en/latest/isamodel.html#study) (ISA Investigation).
### Design Study
Design and create a Study according to the [ISA metadata framework specifications](https://isa-specs.readthedocs.io/en/latest/isamodel.html#study) (ISA Study).
### Design the next Assay
Design and create an ISA Assay in which the inputs (or incomimg samples) are the outputs (or outcoing samples) of the current ISA Assay.
### Experimental assay
Experimental assays refer specifically to laboratory assays.
### Experiment overview
Overview of all Sources and Samples from the ISA Study or from all precedent ISA Assays within a Study, in a searchable table.
### Export ISA
Export the metadata of one Investigation, including the related Studies and Assays, in [ISA-JSON format](https://isa-specs.readthedocs.io/en/latest/isajson.html).
### Insert new Assay
To insert a new assay between two existing ones.
### Investigation
<!--From user guide:-->The investigation is a high level concept that links related studies.

<!--From info icon:-->Investigation is a high level description of the research carried out within a particular Project.
### ISA
The ISA (Investigation, Study, Assay) is a general purpose framework for describing how experiments relate to one another. [ISA metadata framework specifications](https://isa-specs.readthedocs.io/en/latest/isamodel.html#study).
### ISA Overview
* Fullscreen: Toogle between full screen and normal size. A full screen view of the tree can be shown by toggling on the Fullscreen button, and can be reverted by clicking again or pressing the ESC key.
* Graph: It displays as a graph, showing the overall ISA structure. It shows a graphical view of highlighting the item within the network.
  * all nodes: Toogle between expanding all nodes in the graph, or showing just the nearest neighbours.
  * Reset: It resets the graph to its original state, reverting any changes to zoom or moved nodes.
* Split: The Split view provides a combination of the Tree and Graph view, with the tree shown on the right. 
* Tree: It displays with a folder like tree view. The tree view is the default view, and shows the ISA structure as folders, similar to a file browser.



### Modelling analysis/analyses
Modelling analysis refer specifically to simulations (in silico experiments) of models.
### New based on this one
It opens a creation form with pre-filled metadata.
### Protocol tab
Tab showing the protocol or SOP applied in the Study or Assay.
### Sources table
Sources table is an interactive table (dynamic tables) for creating, editing and deleting Study Sources.
### Samples table
Samples table is an interactive table (dynamic tables) for creating, editing and deleting Study Samples and Assay samples.
### Study
<!--From user guide: A study is a particular biological hypothesis or analysis.-->
From info icon: A Study is a particular hypothesis, which you are planning to test, using various techniques. A Study must belong to one Investigation and it can contain one or more Assays.
### Study design
Tab to interact with protocols, sources and samples in an ISA-JSON compliant experiment.

## Assets
### Attribution
Some assets are based on others, for example, a model may use data from an experimental assay, or a SOP may be a modified version of another. The attribution section allows you to specify when this is the case. As you type in the attribution, related assets will appear in a drop down menu.
### Collection
A Collection is a curated, ordered list of assets (Data Files, SOPs, etc.). They can be used to group assets together under a topic or a theme that don't belong in any other kind of hierarchy e.g. ISA.
### Data file
[Assay specific]
Data files can be any file containing data relevant to an assay (raw data, processed data, calibration information etc). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant data files can be linked directly to the assay via a dropdown menu.
### Document
A document contains information related to a Project. Examples are reports, meeting minutes, deliverables, milestones. A document must be associated with one or more Projects and can be linked to Assays and Events. A document can be part of a collection. There is no specified file format for a document.
### Event website <!-- should this one be here under assets, it's also mentioned under Activities below? -->
Link to an online page related to the event.
### File template
A File template describes conforming Data files. It may be annotated with information about the format and type of data in the Data files. Annotations are *not* about the File template itself. For example, a File template that is a Word document may describe conformant PNG images.
### Maintainer
One difference from other asset types is that Collections have “maintainers” instead of “creators”. Maintainers have “edit” rights to the Collection - the ability to add and remove items from the Collection.
### Model
A Model is a file containing a computer model of a biological or biochemical network or process. A Model file must be associated with one or more Projects.
* Model format: e.g. SBML, CellML. If uploading directly through SEEK, you will be able to chose from a drop-down list
* Model type: what kind of mathematical equations the model contains e.g. ODE, algebraic

### Preferred execution or visualisation environment <!-- should this be a bullet under model header or is this field also somewhere else? -->
How do you run a simulation on your model? This field should provide a link to a tool or resource which would allow you to run your model
### Placeholder
[Assay specific] A Placeholder indicates data that will be consumed, used or produced when a Project is enacted. Placeholders are used when the structure of a Project is defined, but, because the Project has not yet been fully enacted, the data may not yet be known. When the data is known, the Data File may be associated with the Placeholder it satisfies. Placeholders may be used anywhere a Data File can be.
### Publication <!-- the text is more of a how-to than a definition, perhaps rephrase and remove images? -->
If your asset is directly related to a publication you can link the two together. Publications registered within your project can be selected from a drop-down menu. If the publication is in another project you need to check the box that says 'associate publications from other projects'.
### SOP
[Assay specific]
SOPs are standard operating procedures which describe the protocol required to reproduce the assay. They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant SOPs can be linked directly to the assay via the dropdown menu.
### Workflow <!-- took the definition from Workflow hub, but it mentions Teams. Should that sentence be removed, should we mark this as instance specific, so that users in other instances don't get confused, or just ignore the added confusion this might cause? -->
A Computational Workflow describes the complex multi-step methods that lead to new outputs. A Workflow must be associated with one or more Teams.
### Version History <!-- don't know what to add here, took text from uploading-new-versions.md -->
When there are minor modifications, improvements or error corrections to an Asset, a new version can be created. If the new version changes the original intention or purpose of the asset, you should instead create an entirely new asset.

## Activities
### Announce an Event
To create a new event.
### Event
From info icon: Events associated with one or more Projects, happening on specified dates and at a specific location, actual or virtual can be registered in SEEK.
### New presentation
To create a new presentation.
### Presentation
<!--From info icon:-->Presentations associated with one or more Projects can be registered in SEEK.

## Samples
### Attributes
Attributes are qualities, features or characteristics of samples.
* Description: description or definition of the attribute.
* Name: name of the attribute.
* Order: to arrange the order in which the attributes are listed.
* Persistent ID: a link (IRI or URI) to a term defining or identifying the attribute.
* Required?: to make the attribute mandatory.
* Title?: to make the value given to the attribute to act as title of the sample.
* Type: to define the type of attribute.
* Unit: quantity used for measuring something.
* ISA tag: ISA tags define the relation of each attribute to either the sample (output) or the protocol, following the categories specified by the ISA model.


### Attribute types
The type of attribute determines the syntax of acceptable values for the attribute. <!--who can edit what CV?-->
* Boolean: a true/false declaration; 1 or 0 can also be accepted.
* ChEBI
* CHEBI ID: an identification for a specific chemical structure registered in the ChEBI database (https://www.ebi.ac.uk/chebi/) (e.g. CHEBI:17234).
* Controlled Vocabulary: the single acceptable value for the attribute must be a predefined term that has to be chosen from a given list of terms (controlled vocabulary).
* Controlled Vocabulary List: the single or multiple acceptable values for the attribute must be one or more predefined terms chosen from a given list of terms (controlled vocabulary).
* Date: a selected date in the format YYYY-MM-DD; it will be visualised as e.g. 2nd December 2016.
* Date time: a selected date and time, in the format YYYY-MM-DD HH:MM; it will be visualised as e.g. 2nd December 2016 13:15. <!--is this a standard? time zone?-->
* DOI: syntax of Digital Object Identifier (DOI).
* ECN
* Email address:  e.g. support@fair-dom.org
* InChl
* Integer: a whole number; not a fraction (e.g. 1, 2, 3, 4).
* MetaNetX chemical
* MetaNetX compartement
* MetaNetX reaction
* NCBI ID
* Real number: a number that can be a fraction and include a decimal place, e.g 1.25
* Registered Data file
* Registered Sample: the acceptable value for the attribute is an internal link to one sample registered within SEEK, from one selected sample type.
* Registered Sample (multiple): the acceptable values for the attribute are internal links to one or multiple samples registered within SEEK, from one selected sample type.
* Registered Strain: an internal link to a strain registered within SEEK.
* String: a sequence of characters (e.g Blue).
* Text: a longer alphanumerical entry (e.g. The 4th experiment in the batch, it was sampled late, so may not be as accurate).
* URI: a Uniform Resource Identifier, which for example may relate to an ontology term
* Web link: a link to a specific web page (e.g. http://fair-dom.org).

### Controlled Vocab
* Title: name of the list of terms.
* Description: description of the controlled vocabulary.
* Ontology: to select one ontology available from the Ontology Lookup Service; terms from the selected ontology will be imported in the controlled vocabulary.
  * Include root term?: to include the root term in the list of terms; otherwise, only children of the root term will be included.
* Terms: terms fetched from one ontology available from the Ontology Lookup Service or new terms created by users. <!--who can edit what CV?-->
  * Label: name of the term as fetched from the ontology or given by the users.
  * URI: the link (URI) to the term as fetched from the ontology or given by the users.
  * Parent URI: the link (URI) to the root term of the term in question as fetched from the ontology or given by the users.

### Sample
<!--From info icon:-->A Sample is an entity (material or data) that can be converted into a new item (material or data) via a process (SOP), physical or computational. Samples must be associated with one or more Projects.
### Sample type
<!--From info icon:-->A Sample Type is a form with samples' attributes needed to describe and create samples in SEEK. A Sample Type must be associated with one or more Projects.
* Spreadsheet template: to create a Sample Type in SEEK starting from an excel spreadsheet file. The name of the first sheet or tab must contain the word "sample". The Sample Type created based on the spreadsheet template has attributes based on the column heading in the first row of the first sheet.
* Template.xlsx: to download a Sample Type registered in SEEK as an empty (without samples) spreadsheet "template.xlsx". Column heading and associated dropdown list will be downloaded as well.

### Experiment Sample Templates
<!--From info icon:-->Experiment Sample Templates are blueprints that can be reused and applied to Study and Assay for describing Samples within experiments compliant with the ISA framework (ISA-JSON compliant). Experiment Sample Templates must be associated with one or more Projects.

Experiment Sample Templates act as blueprints to create Sample Types within ISA Studies and ISA Assays. The same Experiment Sample Template can be (re)used multiple times to create Sample Types in different ISA Studies or ISA Assays.

### View Samples
To visualise samples from one Sample Type in a searchable table.
* Export table: to export all samples from a Sample Type as .csv file.

<!--## General attributes
-### Citation
### Creator
* Additional credit
* New Creator
  * Given Name
  * Family Name
  * Affiliation
### Description
### Discussion channel
### Extended metadata
### License
### Organism
* Display name
* NCBI Taxonomy URI
### Position
### Publish
### Sharing
### Submitter
### Strain
* Based on
* Comment
* Gene affected
* Genotypes
* Kind of mutation
* Phenotypes
* Provider name
* Provider's strain id
* Synonym
### Tags
### Title-->

## Actions
* Administer Project members
  * Add members: to add registered users to the project, using one or more institutions. 
  * Mark/Unmark user as inactive: to manage items of registered users that are not using the platform anymore.
  * Pending changes: list of changes that have not been confirm yet. Pending changes will not be applied if not confirmed.
  * Project members: list of all members of the project, grouped by institution. A project member can be listed multiple times if he/she has been added to the project using multiple institutions.
* Administer Project members roles: to assign or remove administrative roles within the platform.
* Delete: to delete an item. An item can only be deleted if there are no items or people associated with it.
* Edit: to edit metadata of an item.
* Make a snapshot: a way of freezing a version of a public Investigation, Study or Assay in its current state, so that even if changes are made over time, the frozen version can be accessed. Public related items can be included or excluded in the snapshot.
* Manage: to manage
  * Association with Projects
  * Sharing permission settings
  * Creators
  * Sharing link
* Order: to arrange the order in which multiple Investigations, Studies and Assays are visually listed within Project, Investigation and Study, respectively.
<!--* Populate: to populate the structure (ISA, metadata what???) of the project via a compatible tsv file previosly uploaded to the same project.-->

## Add new
To create new Investigation, Study and Assay from the overview page of a Project, Investigation or Study, respectively, even if the newly created item can be associated with a different Project, Investigation or Study from the one selected in the first place.

Also to create an asset immediately associated with the currently selected Assay. The assat can still be associated with different project than the one associated with the Assay.
## Asset report
Short report about items that have been shared outside of the project. <!--more detailed needed? no extra info in the guide-->
## Dashboard
Page containing various charts presenting metrics on activity within the programme or project over a given time period.
## Download
To download assets for which sharing permissions allows the download for a user.
## Experiment view
(aliases: Single Page)
To visualise Experiments (Investigations, Studies, Assays) and the linked SOPs in the Project in a tree view on the left side of the page, while each item’s details are shown and accessible from the center of the page. Only samples created within ISA-JSON compliant experiments are shown in Experiment view.
## Overview
Tree view of the items associated with the project. The associated Programme is also shown.
## Request Contact
To send an email to the submitter of the item to show your interest for it.
## View content
To visualise the content of the file in the browser.
## SEEK ID
Unique identifier within the platform.
## Activity
* Created: creation date of an item, e.g. 4th Dec 2012 at 17:38 (Time Zone unkown).
* Downloads: number of times the item has been downloaded.
* Last updated: date of when an item has been last edited, e.g. 26th Jun 2015 at 10:27 (Time Zone unkown).
* Last updated by: user that last edited an item.
* Views: number of <!--UNIQUE?--> views of an item. <!--based on ??? (dobled clicks?).-->

## Browse
To browse the content of one specific item category at the time (e.g. Documents).
* Query: to search for a specific query within the selected category. The search will attempt to find partial matches for the search term.
* Faceted navigation: to refine search results based on multiple attributes available.

### Condensed
The condensed view has collapsible items that make it easier to view and browse more results in a single results page.
### Default
By default, the content is listed as cards, providing title and some basic information.
### Table
The table view shows more results at once. A small set of attributes about the items are shown as columns. This set can be extended and customised to include or remove attributes related to that item type, as well as choosing their order.
## Overview
Tab showing basic information about the selected item.
## Related items
Tab showing items related to the selected one.
## Search
To search for a specific query. The search will attempt to find partial matches for the search term in all item categories. The search can be restricted to one specific item category (e.g. Documents), as for browsing.
### External
The search can be extended to incude results from external online resources Linked? Integrated? with FAIRDOM-SEEK.
### Advanced search with filtering
To access the query and the faceted navigation option for one specific item category (e.g. Documents). 

## Storage Usage
Storage metrics, for Programmes and Projects, available to FAIRDOM-SEEK administrator. It provides the total size of all Programme or Project assets.
## Change picture or avatar
Custom graphic for a secific item.
## (number)
Number of items of a category (e.g. Documents) visible to you.
## (number + number)
* first number: number of items visible to you.
* second number: number of items hidden from you.

## Integrations
### Bio.tools
To fetch bio.tools identifiers.
### Copasi
To download a public SBML format model from FAIRDOM-SEEK to a locally installed Copasi application and start the simulation in Copasi.
### JWS online
To visualise the model in JWS online.
### DOI minting
To assign a DOI, which is a persistent identifier, to the snapshot, via DataCite.
### LifeMonitor
To apply LifeMonitor algorithm to workflows.
### NeLS
To enable linking of datasets stored in the Norwegian e-infrastructure for Life Sciences (NeLS), as well as upload and access of datasets to/from NeLS through SEEK
### OpenBIS
To fetch and register OpnBIS elements in FAIRDOM-SEEK.
### Publish in Zenodo
To publish a snapshot to Zenodo from FAIRDOM-SEEK.
<!--### Project folders
Free folders within a project to group registered items.-->
### Single page
(aliases: Experiment View)
To visualise Experiments (Investigations, Studies, Assays) and the linked SOPs in the Project in a tree view on the left side of the page, while each item’s details are shown and accessible from the center of the page.
### Compliance with ISA-JSON schemas
Whether the option to comply with the ISA-JSON format specification is enabled. The user will be able to create Investigation, Study and Assay according to the ISA-JSON specification, and to export information as an ISA-JSON file. Requires 'Single Page enabled', 'ISA enabled' and 'Samples enabled'. 'SOPs enabled' is recommended.

If enabled, an option appears to upload default Experiment Sample Templates to specify instance-wide ISA-JSON compliant schemas.
