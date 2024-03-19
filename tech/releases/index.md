---
title: FAIRDOM-SEEK releases
layout: page
---

# FAIRDOM-SEEK Releases

**Latest version - {{ site.current_seek_version }}**

Please see [Getting FAIRDOM-SEEK](/get-seek.html) for details about installing SEEK

If you have any comments or feedback about a release, then please [Contact Us](/contacting-us.html)

## Version 1.15.0

Release date: _March 2024_

* Licenses are now linked to SPDX identifiers, with support for more open source licences.
* A sitemap.xml is generated for public content.
* Samples extracted from a template are now editable and have their won sharing policies and associated projects (previously bound to the tempalte datafile)
* Detect and warn of duplicate samples during extraction
* Samples related to a DataFile are shown if linked together, as well as if the samples originated from the DataFile
* Allowing free text for a Controlled Vocabulary sample attribute, which can be set as allowed for the attribute as part of a defined Sample Type.
* Improved Citation selector UI.
* Performace improvements to allow a Controlled Vocabulary to be populated from a large number of terms from an ontology
* Can define multiple root nodes from an ontology tree when populating a Controlled Vocabulary
* UI improvements when selecting Projects and Institutions for sharing permissions, making them searchable and easier to find in a long list
* Configuration allowing Project requests to be automatically approved for site managed programmes.
* Importing projects from a Data Management Plan that conforms to the RDA DMP Common Standard
* Performance improvements when viewing Data files - checking for matching sample types has been improved and now happens asynchronously
* UI improvments for nested Extended metadata
* Magnify icon next to a file now supports Explore if it is an Excel file
* Admin area that lists Extended Metadata definitions and allows them to be disabled
* Performance improvements when deleting items, especially large numbers of samples tied to a deleted DataFile
* Improvements to the deletion of content-blobs (which describe the registered files) and protection against them being reused after deletion
* Docker compose now recommends MySQL 8
* Fix to LS Login authentication configuration
* Support for generic OpenID Connect authentication to be configured
* Extended Metadata write API, and documentation for both read and write.

For a full list, see [closed issues for 1.15.0](https://github.com/seek4science/seek/milestone/19?closed=1)

## Version 1.14.2

Release date: _2nd February 2024_

A patch release that includes some important bug fixes and improvements:

* Significant performance improvements for jobs updating the authorization tables.
* Stop displaying usage metrics (views, downloads) from list items, due to a large overhead. The metrics are still available when viewing an individual item.
* Allow users to override http response code validation, but with a warning, when attempting to register and item via a URL - as some servers do not always provide the correct response code.
* Fixes to the BioModels search to better handle unexpected JSON responses, or where information is missing.
* Fix to parsing Excel spreadsheets which have errors reported in the logging, but the errors don't prevent the spreadsheet being successfully parse.
* Keep the "External Search" box ticked between searches.

For a full list, see [closed issues for 1.14.2](https://github.com/seek4science/seek/milestone/21?closed=1)

## Version 1.14.1

Release date: _13th November 2023_

A patch release that includes some important bug fixes and improvements:

* Fixed a problem that prevented extracted samples that include links to other samples being successfully registered.
* Fixed an error that was occurring when a sample attrribute PID was inadvertently set to an invalid IRI.
* A fix to some cases where the submit button was always disabled when attempting to "Request membership" to a Project.
* The integration with the Ontology Lookup Service has been updated to use version 4. 
* The sample attribute type "Registered Sample (multiple)" has been renamed "Registered Sample List" to be consistent with other types.
* The sample attribute type "Ontology" has been removed, as it was just duplicate of "Controlled Vocabulary". We are looking at ways to distinguish between
plain CV's and ontology based CV's in the UI.
* Allow a Controlled Vocabulary that has been populated from an ontology via the Ontology Lookup Service to now also allow additional terms to be manually added.

For a full list, see [closed issues for 1.14.1](https://github.com/seek4science/seek/milestone/20?closed=1)

## Version 1.14.0

Release date: _12th October 2023_

A major release that contains a number of improvements, upgrades and bug fixes, including:

* **Upgrade of Ruby**, from Ruby 2.7 to Ruby 3.1. 
  * This gives improved speed and overall performance, along with keeping up with security patches.
* **Upgrade to Rails**, to the latest 6.1 release.  
* **Nested [Extended Metadata](/tech/extended-metadata)** (previously referred to as Custom Metadata).
    * Extended Metadata allows items to be customized with additional typed metadata, similar to samples, and was used to support MIAPPE along
    with some bespoke installations. 
    * Extended Metadata can now be nested, i.e one Extended Metadata type definition can include a reference to another, 
      and these will be nested together in a single form.
    * The inner Extended Metadata type can also now be defined as a list, with the form allowing new items to be added or removed.
* **Gatekeeper behaviour** refresh and fixes
  * Many bugs fixed, along with improvements and refinements.
  * Fixes to notifications for when a gatekeeper intervention is required.
  * Fixes to tracking items waiting to be published, and updating the list when they are rejected or approved.
  * Fix to better keep track of the full sharing permissions whilst a request to make public is being reviewed by the gatekeeper,
    and have them applied correctly when approved.
  * Users can now cancel a publishing request.
  * Added support for Samples.
  * Improved integration with DataHub and the Single Page View.  
  * Updated [documentation](/help/user-guide/roles.html#asset-gatekeeper).  
* **Viewing of Excel files in the browser** for all asset types (previously only Data Files were supported).
* **Event filtering improvements**.
  * Includes the full set of common filters available for other items, plus the addition of Event specific filters.
* **Fix duplications in the ISA graph and tree**, particularly for publications.
* **Updated and unified auto complete text fields** to use an improved UI component and be consistent throughout.
  * Type ahead fields that autocomplete (e.g. tagging, sample controlled vocabularies) have now been updated to use [select2](https://select2.org/) throughout.   
* **Programme creation request notifications** to adminstrators are now shown in the browser as well as by email.
* **Explanatory text for Programme creation** has been provided.
* **Navigating from broad search results across all types, to the full list** with filtering for a specific type has been made clearer .
* **Better phone and tablet support** for some places in the UI.
* **[FAIR Signposting](https://signposting.org/FAIR/) support** option added.
  * Data dumps containing aggregated Bioschemas metadata generated daily for each asset type.
* **bio.tools** support extended to API.
* **Workflow metadata improvements**.
  * Automatic identification of license from `LICENSE` etc. files in Git repositories or RO-Crates.
  * Recognize additional metadata from CFF files.
  * Add "Deprecated" as a maturity level option.
* **Citation improvements**.
  * Citations can now be generated from CFF files for resources without a DOI.
  * Citation style select list can now be filtered.

For a full list, see [closed issues for 1.14.0](https://github.com/seek4science/seek/milestone/16?closed=1)

## Version 1.13.4

Release date: _14th June 2023_

A small patch release that contains some small bug fixes:

* Fix for handling redirects correctly when registering an item by URL.
* Fix to handle items registered as a remote URL - when the URL needs authorization it is always shown as an external link.
* Fix for a missing python dependency (filelock), which is required for processing CWL workflows. 

We have also provided details about [installing Ruby 2.7 on Ubuntu 22.04](/tech/ruby-2.7-ubuntu-22.04). 

For a full list, see [closed issues for 1.13.4](https://github.com/seek4science/seek/milestone/18?closed=1)

## Version 1.13.3

Release date: _16th May 2023_

A small patch release that contains bug fixes and small improvements:

* Ability to recursively select items in the tree when batch changing permissions
  * ( for 1.14 this will be further improved and combined with batch publishing which is a very similar action)
* When running with Docker, a new PUMA_WORKERS_NUM environment variable can be used to control the number of puma
  workers, overriding the default that is set to the number of available processor cores
* Fix for when combing filtering with ordering by views or downloads
* Fix for publications incorrectly showing a license that cannot be set

For a full list, see [closed issues for 1.13.3](https://github.com/seek4science/seek/milestone/17?closed=1)

## Version 1.13.2

Release date: _14th April 2023_

A small patch release that contains several bug fixes and small improvements, including

* Ability to tag Investigations and Studies, providing better overall consistency
* Fix duplicate projects appearing in Workflow RO-Crates
* Sort items by view or download counts in the filtered search index views
* A new Sample attribute type, _Controlled Vocabulary List_, that supports multiple terms selected from a Controlled Vocabulary as an array
* Fix to correctly provide the content length in HTTP headers for downloads that was missing in some cases, and also added the Content-MD5 header to include the md5 checksum
* Programmes are now listed in MyItems, and related items generally, if the user is the Programme Administrator but not directly a member of a related Project
* Space out daily background jobs so that they don't all run at once, avoiding potential memory issues  
* Upgrade of Rails to the 6.1.7.2 version, and also Ruby to the 2.7.8 version

For a full list, see [closed issues for 1.13.2](https://github.com/seek4science/seek/milestone/15?closed=1)

## Version 1.13.1

Release date: _2nd February 2023_

A small bugfix patch release ...

* Fix to forcing a copy when registering data via a URL, using the Upload a copy checkbox.
* Group together notification emails, to prevent many emails for the same error being sent in quick succession.
  The are now sent in groups of increasing size, within a configurable time period.
* Fix to prevent links being displayed, when displaying the text that was used for a search.

For a full list, see [closed issues for 1.13.1](https://github.com/seek4science/seek/milestone/12?closed=1)

## Version 1.13.0

Release date: _12th January 2023_ 

A major release with broad number of changes, including many small changes and bug fixes not listed here.
The high level changes include:

* **Maintenance period** - code tidying, removing old unused features, refactoring.
* **Rails 6.1 upgrade**.
* **Workflow support improvements**:
  * **Git** repository support:
      * Import from git repository,
      * Add and modify files dynamically,
      * Preview and download individual files,
      * Versioning via Git.
  * **Bio.tools** integration for workflow steps,
  * **Citation CFF** support,
  * **Jupyter** notebook rendering,
  * **RO-Crate** parsing and creation fixes,
  * Improved workflow **diagram** generation,
  * Workflow **maturity flag** and filter,
  * **LifeMonitor** integration - filter by test status.
* **Sample enhancements**:
    * Extraction performance improvements,
    * Improved error handling and reporting during sample extraction,
    * Sample types have contributor shown, and now supports creators,
    * Filtering and search view now available for samples and sample types.
    * JSON API improvements.
* **Integrated [TeSS](https://tess.elixir-europe.org/) search** for Events.
* **Timezone information** provided for Event start and end dates.
* **Search improvements**:
  * Fix to the order of search results,
  * Improvements to indexing.
  * Harmonization between general search and searching and filtering.
* **Show the last person** that updated an item (shown only to project members).
* **Improvements to the table view** of items, adding more columns and making more consistent.
* **Tagging projects from the EDAM** ontology, and made easier to extend with other ontologies in the future.
* **API testing and documentation** improvements.
* **Project creation and join requests** fixes and improvements, including:
    * Other administrators are notified when a request is responded to.
    * Ability to delete a request without responding, for handling spam or duplicates.
* **Descriptive help text** for each creatable entry, show in the Create or Browse pages that link off to documentation where available.
* **IBISBA enhancements**:
  * iPOP - to populate a Project and ISA information from a spreadsheet template,
  * File templates and Placeholders.
* **Publication improvements**:
  * Option to support the upload of full text PDF or link,
  * Any number of related links,
  * Option to allow editing imported publications.
* **Settings caching** - giving a page load speed improvement
* **Cookie consent banner** improved to give more control over which cookies are set, and when content from other sites can be embedded.

For a full list, see [closed issues for 1.13.0](https://github.com/seek4science/seek/milestone/10?closed=1)



## Version 1.12.3

Release date: _5th August 2022_

Small bug fix release that patches an issue introduced by the previous release causing a 404 when trying to filter using a search term.

## Version 1.12.2

Release date: _28th July 2022_

Small update release that includes

* A fix to search results not being correctly displayed in order of relevance
* A fix that correctly displays the tab, when linking to a tab (such as related items) using the bookmark (e.g <https://fairdomhub.org/programmes/20#projects> )

For a full list, see [closed issues for 1.12.2](https://github.com/seek4science/seek/milestone/11?closed=1)

## Version 1.12.1

Release date: _24th June 2022_

Small release with some bugfixes and small improvements. In particular a security fix, so **we recommend upgrading to this version**

* An overhaul and refresh of Gatekeeper behaviour, fixing bugs and allowing repeat requests to be sent following a previous rejection.
* Fix to an error when interacting with the Ontology Lookup Service API, which affected creating and using sample types and controlled vocabularies in some cases.
* More tolerant URL checking when registering a remote asset. 
* Removed option to generate a DOI for a hidden version.

For a full list, see [closed issues for 1.12.1](https://github.com/seek4science/seek/milestone/9?closed=1)

## Version 1.12.0

Release date: _6th May 2022_


For a full list, see [closed issues for 1.12.0](https://github.com/seek4science/seek/milestone/6?closed=1)

This version includes:

* **Collections** - the ability to bundle together items that are conceptually related into an ordered list, which can
  then be shared together as collection.
* **New customisable front landing page** - a cleaner front page, with more useful information, that can be customized
  and configured per SEEK instance.
* **Sample attributes enhancements** - attributes can be provided a description, which provides more details when
  entering or viewing a sample. They can also be given a persistent identifier, to provide a semantic definition of the
  attributes meaning.
* **Improvements to how creators can be credited** - there is now an improved UI for crediting the creators, or authors,
  of assets. Extra information, such their as ORCID and affiliation, can now be added for each creator, even if they are
  not registered in SEEK. The exact order of how creators appear can also be specified.
* **Explicit ordering of Investigations, Studies and Assays** - each can be provided with an explicit order within the
  other, rather than the order they are added. They can re-ordered at any time.
* **Ability to link a Sample to multiple other samples** - previously, a sample could only be linked to a single other
  sample. This has now been updated to allow a one to many relationship as long as the samples are of the same type.
* **EDAM annotations for workflows** - describe the workflow operations and topics from the EDAM ontology. This is also
  planned to be reused to describe data types and formats.
* **Simpler branding settings** - for SEEK administrators, the settings to give particular branding to an instance were
  complicated and confusing. This has now been simplified, and organised in logical groups.
* **Moved related items into a tab** - the list of related items associated with the item shown have now been moved into a separate tab, rather than needing to
  scroll to the bottom of the page. There are also plans to move other information, such as versions and files, into
  additional tabs.
* **Fixes and improvements running to under a relative URL** - for those running SEEK under a relative URL (
  e.g. https://mysite.com/fairdom-seek/), some issues were found with incorrect links. These problems have now been
  fixed, for both Docker and Bare-metal installations, and the testing process improved.
* **Batch registration of Samples through the API** - it is now possible to register Samples in batches through the API,
  rather than one by one, to reduce the number of necessary calls and performance.
* **Updated to use latest version of Apache Solr** - the Apache Solr that was being bundled with SEEK, was no longer
  being maintained and updated. This locked SEEK to an older version of Java. Solr has now been separated, that can be
  installed separately using the latest version, along with an updated configurations. A new updated Docker image is
  also now available.
* **Workflow API enhancements** updates to support the GA4GH TRS API, allowing one click execution of Galaxy workflows, and support for registering an RO-Crate through the API.
* **Extending the items a workflow can be linked to** - ability to link a workflow to Datafiles (as test, example and training data),
  Documents, SOPs, and Presentations as well as Publications.
* **User defined workflow types** - users can now add to the selection of workflow types, if they can't find the one
  they need, when registering a workflow.

For a full list, see [closed issues for 1.12.0](https://github.com/seek4science/seek/milestone/6?closed=1)

## Version 1.11.3

Release date: _3rd November 2021_

A small update to fix a possible upgrade issue (see [https://github.com/seek4science/seek/issues/770](https://github.com/seek4science/seek/issues/770))

For a full list, see [closed issues for 1.11.3](https://github.com/seek4science/seek/milestone/8?closed=1)

## Version 1.11.2

Release date: _6th October 2021_

A small update release with minor changes and bug fixes, in particular:

* Finalised Sample and Sample Type read/write API, along with completed documentation.
* Bioschemas improvements with greater compliance, and the addition of _conformsTo_ clause to indicate which version is
currently being used.
* Recommended licenses, which appear at the top of the list. The FAIRDOM-SEEK admin has the ability to set and change these under Settings.
  The license ID is now also validated that it is recognised when set through the API.
* Fix to a critical issue with Sample and Custom metadata attributes of type Boolean, which prevented them being set through the UI.
  This also includes a fix to allows an empty value if the attribute is optional.
* Allow project join requests to be approved where the optional Institution Country is missing.
* Show the date a user joined on their profile page, visible to all logged in registered users.

For a full list, see [closed issues for 1.11.2](https://github.com/seek4science/seek/milestone/7?closed=1)

## Version 1.11.1

Release date: _19th July 2021_

A small update release with a few small changes and bug fixes, in particular:

  * Fix to a rarely encountered bug that caused a user to be added to a project with a nil Institution, which could then lead to other problems
  * Fix to remove some warning messages about a duplicate definition of _include_blank_
  * Person responsible for Study has been deprecated and removed from the user interface 

For a full list, see  [closed issues for 1.11.1](https://github.com/seek4science/seek/milestone/5?closed=1)

## Version 1.11.0

Release date: _21st June 2021_

This version includes:

  * **Changes to joining a project during registration**. 
    * During registration a user will no longer be asked to select a Project and Institution, (this was often missed). Instead, they will be prompted to either Join or Create a Project after registration and until they are a member. 
    * [Joining a Project](/help/user-guide/join-a-project.html) now has an easier interface to search and select the projects the users want to join, and to define either a new Institution or select an existing one
    * The Project administrator is notified by email, and is provided with a single page to accept the join request more easily, and is also prompted through the FAIRDOM-SEEK interface if there are outstanding requests.
  * **Simplified Project and Programme creation.** 
    * A user can now more easily request to [create a Project](/help/user-guide/create-a-project.html). The Project creation request can include a Programme if enabled, along with defining a new Institution or selecting an existing one. 
    * If a Programme or site administrator is needed to approve the request, there is a simpler interface to accept or reject quickly, and the administrators are prompted through the FAIRDOM-SEEK interface as well as email.
  * **Site managed Programme.** 
    * FAIRDOM-SEEK can now configured to include a site managed Programme.
    * This can be selected by users who do not want to a Programme to self administer and add additional Projects.
  * **Markdown formatting of descriptions.** 
    * Support has been added for [markdown elements in descriptions](/help/user-guide/general-attributes#description).
    * It includes an editor with shortcuts for common formatting options, together with a preview option.
  * **Ontology based controlled vocabularies.** 
    * FAIRDOM-SEEK now supports Sample attributes limited to controlled vocabularies (CVs) backed by an ontology.
    * This extends the current capability for a controlled vocabulary to be specified by a list of strings.
    * The ontology backed CV's can be easily populated in the User Interface via the Ontology Lookup Service. They may also be populated manually with Internationalized Resource Identifiers (IRI's).
  * **Spreadsheet view for exploring Comma and Tab separated value files (CSV or TSV).** 
    * FAIRDOM-SEEK adds support for exploring CSV/TSV files uploaded as a DataFile.
    * The exploration presents a table view of data.
    * The exploration extends the existing Excel file explore feature.
  * **Condensed view of lists.** 
    * When viewing the standard index page for items, FAIRDOM-SEEK now has an alternative  [condensed view](/help/user-guide/browsing.html) that can be selected.
    * The condensed view has collapsible items, that make it easier to view and browse more results in a single results page.
  * **Table view of lists.** 
    * When viewing the standard index page for items, there is now an alternative view that can displays [items in a table](/help/user-guide/browsing.html).
    * By default, a small set of columns of data about the items are shown. This set can be extended and customised to include attributes related to that item type.
  * **MIAPPE support with custom metadata extensions.** 
    * FAIRDOM-SEEK now adds the ability to extend entities with additional metadata attributes. The focus is currently on extending metadata for Investigations, Studies and Assays to support [MIAPPE](https://github.com/MIAPPE/MIAPPE).
    * The ability is generic and can be used to define custom metadata extensions for any item type; this allows FAIRDOM-SEEK to support different standards.
    * Future versions plan to provide 
      * a UI to allow the  definition of new extensions,
      * pre-defined definitions for repository standards, and also
      * support for MIAPPE observed variables.
  * **Bulk changing of sharing permissions.** 
    * FAIRDOM-SEEK 1.11 adds the ability to [bulk change the sharing permissions](/help/user-guide/bulk-change-sharing-permission.html) of many items in a single step.    
  * **Simplified deleting of Projects.** 
    * FAIRDOM-SEEK now allows the deletion of Projects by the Project administrator, even if the project still has members.
    * The members will automatically be removed
    * Projects that contain assets or Investigations, Studies or Assays cannot be deleted without first removing them.
  * **Run with Copasi button.** 
    * Added ability to download a publicly downloadable model to a local installed Copasi application and to start the simulation in Copasi 
  * **Changing visibility of item versions.** 
    * Historically past versions of an item have been visible to registered users, but not to those logged out (anonymous).
    * FAIRDOM-SEEK now supports all past versions being visible (in accordance with the sharing permissions of the item),
    * The visibility of specific versions can be controlled by the user - completely hiding individual versions if wished.
    * Existing versions continue to follow the original permissions until explicitly changed.

For a full list, see [Closed issues for 1.11.0](https://github.com/seek4science/seek/milestone/2?closed=1)

## Version 1.10.3

Release date: _30th October 2020_

This version includes the following bugfixes:

  * Fix to the external search over BioModels
  * Fixes to doing a search over filtered results, and maintaining the correct order from the search results
  * Adding new version comments for Documents
  * Fix to Dataset schema.org markup
  
[Closed issues for 1.10.3](https://github.com/seek4science/seek/milestone/4?closed=1)  

## Version 1.10.2

Release date: _28th August 2020_

This version includes a few bugfixes:

  * A fix to a validation error when linking to a older publication with no publication type defined. 
  * A fix to adding via a URL, where the remote server doesn't respond to HEAD requests.
  * Better handling of when the attr_encrypted key is missing or wrong, which previously prevented the server starting up.
  * A fix to activity reporting, where a snapshot pointed to a deleted resource.

[Closed issues for 1.10.2](https://github.com/seek4science/seek/milestone/3?closed=1)  

## Version 1.10.1

Release date: _24th June 2020_

This version contains a few bug fixes and security updates, and minor feature additions. 
In particular:

  * Rails upgrade to the latest Rails 5 release (5.2.4.3), along with some other dependencies
  * Discussion links now have an optional label, to be displayed instead of the raw URL
  * Discussion links are now included in the API
  * Model organism has been included in the API
  * The Model image link has been included in the API
  * An improvement to how Submitter and Other creators are displayed, to be less ambiguous
  * Request resource has now been entirely replaced by the improved ability to request contact
  * A fix to a bug that prevented Assays and Assets being unlinked, if there was only 1 Assay

[Closed issues for 1.10.1](https://github.com/seek4science/seek/milestone/1?closed=1)

## Version 1.10.0

Release date: _9th June 2020_

Highlights:

  * Filtered search and browsing:
    * When viewing index page lists, it is now possible to change the sort order, and filter by certain attributes
    * It is also possible to perform a text search over the list, and apply filters to the results
    * Filters across categories have **AND** applied, whereas within a category **OR** is applied
  * Enhanced support for publications:
    * Support for more publication types, including:  _Journal article_, _inproceedings_, _inbook_, etc. 
    Users can update the publication type when editing the publication.
    * Additional metadata attributes including _booktitle_, _editor_, _publisher_, _a remote URL_
    * For publications, which are manually registered or imported from bibtex files, users can edit all fields of publications.
    * For publications registered with DOI, users can refresh the metadata by clicking "edit publication"
    * Improvements to importing publications by a bibtex file
      * Ability to import different types of publications
      * Add more validations to support different types of publications
      * Generate the citation according to the type of publications when there is no DOI or Pubmed ID   
  * Adding one or more Discussion Channel links to all Assets
    * If you wish to provide the ability to open a discussion about an item, one or more links can be added to locations
    such as Slack, GitHub issue, a Forum thread
  * A "Request Contact" button for Assets, to allow a registered user to initiate an email discussion with the owner and creators of that item.
  * Increased zoom level when previewing model images, and ability to view the original in its full resolution
  * Support for 'include' when using the JSON API
    * Allows you to get full details about related resources in a single call ( see [JSONAPI specification](https://jsonapi.org/format/#fetching-includes))
    * For example <https://fairdomhub.org/projects/19.json?include=people> expands information about the people in an _included[]_ block at the end of the top level JSON. 
  * Study Experimentalists attribute has been deprecated - existing entries aren't lost and can be edited, but the attribute has been removed
  for new entries or existing entries where that attribute hasn't been set 
  * Renaming of _contributor_ to _submitter_ - to be clearer about what this attribute represents
  * Update of [BiVeS](https://semsproject.github.io/BiVeS/) - used for model version comparisons, has been updated to the latest available version  
    
  
There have also been many other minor bug fixes and improvements.  

_Note_ that with this version, we moved from JIRA to [Github Issues](https://github.com/seek4science/seek/issues), and
for this and probably future versions have stopped providing links to individual tasks.

---

## Version 1.9.1

Release date: _17th October 2019_

  * Minor User Interface improvements
    * More consistent sorting of lists.
    * Consistent Add New button to add new items linked to the current item. This replaces buttons that only appeared in
    some places - such as the "Add New Data File" for "Assay".
    * Split Edit and Manage action between 2 separate pages, rather than being handled through the same form.
  * Initial support for [bioschemas.org](https://bioschemas.org) / [schema.org](https://schema.org) JSON-LD markup
    * Supporting Project, Taxon, Sample, Event, DataSet, DataCatalogue, DigitalDocument, and PresentationDigitalDocument
  * Validating assay and technology type URI's (particularly when submitting through the API).
  * Managing project members through the API.
  * Fix to an problem and inconsistency with how countries and the country codes are stored and displayed
  
There have also been several minor bug fixes and improvements, 
which are described more within the [SEEK v1.9.1 release notes](release-notes-1.9.1.html)

## Version 1.9.0

Release date: _16th July 2019_

  * Major upgrade of the underlying platform
    * Rails 4.2 → Rails 5.2
    * Updating and replacing affected libraries and dependencies
    * Unifying javascript to use jQuery framework throughout, and removing Prototype references
  * A lot of bugfixes and minor improvements discovered during the upgrade testing  
  * Ability to login with email as well as username
  * Ability to edit previous version revision comments
  * Show the SEEK ID of the selected node when navigating the ISA overview
  * Fix for model files appearing missing for previous versions (don't worry, no files were actually lost)


Changes are also described in the [SEEK v1.9.0 release notes](release-notes-1.9.0.html). 
Please note that many of the bugfixes are those created during the Rails upgrade,
due to changes in the Rails version.

## Version 1.8.3

Release date: _29th May 2019_

Bug fix release:

   * Fix to correctly clean up permissions when a contributor is deleted
   * Additional constraints to prevent invalid permissions, particularly when changing through the API
   * Fix to finding related Organisms to a Sample through an NCBI ID attribute

Changes are also described in the [SEEK v1.8.3 release notes](release-notes-1.8.3.html)         

## Version 1.8.2

Release date: _25th April 2019_

Bug fixes and minor improvements, changes are:

   * Fix to a potential database lock, particularly when registering multiple items in quick succession through the API
   * Ability to edit version revision comments
   * Fix to correctly show the creator of a particular DataFile version
   
Changes are also described in the [SEEK v1.8.2 release notes](release-notes-1.8.2.html)   

## Version 1.8.1

Release date: _18th March 2019_

Bug fixes and minor improvements, main fixes are:

  * Fix to some cases where the RDF wasn't including associated assets
  * Better handling of news feed errors, and avoid cases where they could prevent the front page loading
  * Fixed the order publication authors are displayed in list items  
  * Project Dashboard help link

A full list of changes included in this release can be found in the [SEEK v1.8.1 release notes](release-notes-1.8.1.html)

## Version 1.8.0

Release data: _February 12th 2019_

  * **openBIS integration** has been extended and improved upon, mainly through contributions from [Tomasz Zielinski](https://fairdomhub.org/people/711) 
  of [SynthSys](https://fairdomhub.org/programmes/21). The extensions include linking between Studies and openBIS Experiments, and Assays and openBIS Objects.
  Automation has also been added to automatically detect and synchronise new items. For more information please read our [Guide for using openBIS with SEEK](/help/user-guide/openbis.html).
  **Note** that to use the new features, [openBIS 18.06.1 or later](https://wiki-bsse.ethz.ch/display/bis/openBIS+Download+Page) is required. 
  * A new **Project Dashboard** has been added, to allow project members to view various statistics and trends, including graphs, within their project. 
  For more information please read the [Project Dashboard Guide](/help/user-guide/project-dashboard.html) 
  * **Former project members**, that have been marked as inactive within a project, are now more clearly indicated along with the date they left.
  * **Project start and end dates** can now be defined for a project, which, if defined, are displayed on the Project page.
        
A full list of changes included in this release can be found in the [SEEK v1.8.0 release notes](release-notes-1.8.0.html)   

## Version 1.7.1

Release date: _November 19th 2018_

  * Fix to a bug where the session table column was too small. This sometimes led to a datafile upload problem if the user was in a large number of projects.
  * Show the Project creation date on its _show_ page. (In 1.8 we plan to include the option to specify the project start and end dates).
  * Fix to a bug where some assets couldn't be edited if shared across multiple projects, and the user only belonged to a subset of those projects.
     
A full list of changes included in this release can be found in the [SEEK v1.7.1 release notes](release-notes-1.7.1.html)     

## Version 1.7.0

Release date: _October 15th 2018_

  * **Programme wide sharing permissions** have been added.  The sharing options now include the ability to share across a whole Programme.
  * **ISA graph improvements** - we spent some time revisiting the ISA graph, fixing some underlying issues and making it more usable. It now defaults to showing the tree view, and 
  the graphical view is simplified and highlights the current item and its nearest neighbours. It no longer includes the associated Project and Programmes to avoid unnecessary interlinking 
  and complexity. The intention is that the graph view should provide a quick visual indication of the place of the current item within the ISA network, and provide the ability to explore and navigate 
  over the graph. A separate export function has been provided to all easy generation and download of PNG files for inclusion in reports or presentations. 
  * A dedicated **NCBI ID sample attribute type** has been added, which accepts a number and displays as an identifier URI. If the NCBI id matches an Organism present in SEEK then the link will automatically be made.   
  * Restrictions to **Sample Type visibility** have been added. Sample types are now initially only visible to members of the Project they are associated with, until it starts having Samples associated with it. 
  The Sample Type will become visible outside of the project, and to external users, once one or more samples associated with that Sample type have been made public. This allows more freedom to allow all project members to create
  Sample Types, without the difficulties of having full sharing permissions on Sample types, whilst restricting the Sample Types exposed outside of the Project. 
  * The ability to link **Documents to Events**, and vice versa, has been added.

A full list of changes included in this release can be found in the [SEEK v1.7.0 release notes](release-notes-1.7.0.html)

## Version 1.6.3

Release date: _August 21st 2018_

  * Fix to prevent users flagged as having left a project being able to access items shared with that project 
  (they can still access their own items, or items also shared within them in other ways)
  * Fix to an error occuring when a large number of Documents are associated with an Assay
  * Fix to manually adding an organism manually through its NCBI ID, when the ID URL is provided with surrounding spaces.


A full list of changes included in this release can be found in the [SEEK v1.6.3 release notes](release-notes-1.6.3.html).

## Version 1.6.2

Release date: _July 5th 2018_

  * Fixed a bug when viewing a Project page that has more that 5 visible Documents associated with it.
  * Avoid warning about missing projects when uploading a standard Excel file, being mistaken as RightField template.
  * When running SEEK through Docker, write the Puma output and error logs to files.
  
A full list of changes included in this release can be found in the [SEEK v1.6.2 release notes](release-notes-1.6.2.html).  

## Version 1.6.1

Release date: _June 20th 2018_

Bugfixes and some small improvements, in particular

  * Fixed an error when uploading a DataFile with no Assays in the database (only seemed to affect Docker)
  * Fixed a mime type problem when uploading files, in particular CSV files being incorrectly treated as Excel
  * When using the DataFile upload wizard, the arrow keys no longer affect navigation whilst editing a field
  * Recognise and handle Excel (macro-enabled), XLSM, files as standard Excel files.
  * Within the admin area, when showing the queued jobs, there is no a button to clear failed jobs. 
  * You no longer have to accept the (blank) Terms and Conditions when setting up the first user for a new SEEK installation.
  
There have also been a few other smaller fixes and improvements, a full list of changes included in this release can be found in 
the [SEEK v1.6.1 release notes](release-notes-1.6.1.html).
                                                                  
 

## Version 1.6.0

Release date: _June 8th 2018_

Major changes include:

  * Interlinking the [**ELIXIR Norwegian e-Infrastructure for Life Sciences (NeLS)**](https://nels.bioinfo.no/) with the SEEK platform. 
 This will provide NeLS and SEEK users with unprecedented opportunities for storing, sharing, 
 and archiving of data in ways that comply with the FAIR principles.
  * Our second installment of our [**JSON API**](/help/user-guide/api.html), in particular to include support for **writing** and submitting new entries in SEEK. 
    Most write abilities are now available through the API including creating Datafiles, SOPs, Models, 
    Investigation, Studies and Assays and linking them together. More details about the api can be found in the 
    [API Guide](/help/user-guide/api.html), with more technical details found in the [JSON API Overview](/tech/api/index.html) 
  * Changes to the  **DataFiles upload workflow**, along with better RightField template support. The flow has been changed such that the 
 file is registered before providing additional details. This allows information to be extracted and details automatically populated where
 possible. The supported templates are now provided as part of the templates generated for Sample Types, but will soon be available more widely.
  * DataFile metadata is now provided through a [**Wizard**](/help/user-guide/data-file-upload-wizard.html), split into logical steps, that can easily be stepped through.
  * Assays can be created and linked to the DataFile being submitted as part of the same process. This can either be manual or from the details provided within
 a template.
  * Support for a new **Document** asset type. This is to represent general documents that do not fit as other asset types - such as
  reports or meeting minutes.     
  * Ability to enable and provide **Terms and Conditions**, that need to be accepted as part of the registration process
  * Creating **DOI's** for individual items has been made clearer and easier to use.    

There have also been many other bug fixes and small improvements.
A full list of changes included in this release can be found in the [SEEK v1.6.0 release notes](release-notes-1.6.0.html).
 
 
## Version 1.5.2

Release date: _February 20th 2018_

Bugfix release that includes:

  * Minor security fixes, following an external security review  (more details available later)
  * Image scaling fix - where some avatars were scaled down, and then expanded causing them to appear blurred.

A full list of changes included in this release can be found in the [SEEK v1.5.2 release notes](release-notes-1.5.2.html).
  

## Version 1.5.1

Release date: _January 11th 2018_

Bugfix patch release that in particular fixes:

  * An error that prevented people entries being deleted in some cases.
  * An error turning exception emails on or off in the admin settings
  * An error that prevented a Programme submission being rejected
  
A full list of changes included in this release can be found in the [SEEK v1.5.1 release notes](release-notes-1.5.1.html).
  

## Version 1.5.0

Release date: _December 11th 2017_

This is quite a large release, and the main highlights include:

  * Our first released version of our **JSON API**. This has been built to conform to the [JSON API](https://jsonapi.org) specification, 
    and is documented on [SwaggerHub](https://app.swaggerhub.com/apis/FAIRDOM/SEEK/0.1).
    This read API has been developed in conjuction with, and feeds into, a write API which will be released incrementally
    in subsequent releases. For more details please read [API](/help/user-guide/api.html).
  * Incorporating the new **[JERM 2 ontology](https://jermontology.org)**, along with updates and extensions to the RDF produced by 
    SEEK.
  * **Migrated legacy sharing permissions**: Given registration for SEEK is open to anyone, 
  we have removed the ability to administer sharing permissions of items for _“all registered users”_. 
  This ability was removed from the user interface several versions ago, but a number of items retained this legacy sharing permission. 
  Items shared with “all registered users” have now been updated so that their sharing permission is “project wide” instead, according to the projects the item is associated with. 
  This restricts the audience which can interact with the item. 
  Owners and managers of items are still free to continue to choose and change the sharing permissions as they wish.
  * If users wish to **request to join a project**, but do not know the user that administers it, there is now a button available to do so. A message
  will be sent the administrators of those projects with additional details. When added to a project, the new member is automatically notified
  by email. A request can only be sent once every 12 hours.
  * **DOI's and ORCiD** identifiers, where used or created, are now displayed more clearly in various views and lists.



A full list of changes included in this release can be found in the [SEEK v1.5.0 release notes](release-notes-1.5.0.html).


## Version 1.4.1

Release date: _September 4th 2017_

Contains bug fixes and minor improvements, and also in particular a reorganisation and update of the Administration
areas of SEEK.

A full list of changes included in this release can be found in the [SEEK v1.4.1 release notes](release-notes-1.4.1.html).



## Version 1.4.0

Release date: _July 4th 2017_

The main change in this version is a complete upgrade of the underlying platform to the Rails 4.2, which supports Ruby 2.2.

Other major changes are included below:

  * Upgrade to Rails 4 platform
  * Project sharing permission defaults for when adding new items for a Project.
  * Events are included in the ISA graph, and the text formatting has been improved
  * More descriptive tab titles  
  
There have also been many bug fixes (although many of the bugs listed in the release notes relate to problems 
encountered during the Rails upgrade)        

_(A future upgrade to Rails 5 is planned for the future once that version has stabalised and our dependencies have
been updated)_
  
A full list of changes included in this release can be found in the [SEEK v1.4.0 release notes](release-notes-1.4.0.html).  


## Version 1.2.3, 1.3.3

Release date: _June 23rd 2017_

Patch release to fix an issue, where items shared with "all registered users" in older versions of SEEK may be shown publicly.

## Version 1.3.2

Release date: _May 10th 2017_

Patch release that fixes some bugs, in particular:

  * Fixes an issue to do with editing sample types after a validation error
  * Fix to displaying samples or sample types linked to a large number of projects or other associated items
  * Clarifies publication authors when the person that registers it is not an actual author
  * Fix for when using older version of Sqlite3
  
A full list of changes included in this release can be found in the [SEEK v1.3.2 release notes](release-notes-1.3.2.html).  

## Version 1.3.1

Release date: _April 27th 2017_

Patch release that fixes a few small bugs, in particular:

  * Fix to sharing form for Studies and Assays
  * Fix searching error where a spreadsheet was incorrectly expected
  * Fix selection of default license for a project
  * Fixes related to strains and extracting sample strains 

A full list of changes included in this release can be found in the [SEEK v1.3.1 release notes](release-notes-1.3.1.html).

## Version 1.3.0

Release date: _March 17th 2017_

![new_sharing_matrix](/images/release-notes/openbis.png)

This is the first public release that supports [openBIS](https://fair-dom.org/platform/openbis/) integration. This version includes

  * Ability to link and browse an openBIS space and datastore, and browse DataSets
  * Easily register an openBIS DataSet with SEEK as a DataFile
  * Browse and download individual DataSet files, or download as a whole zip file.
  * Search indexing of registered openBIS DataSets
  * Automatic synchronisation with openBIS spaces and DataSets
  * An [openSEEK bundle](/tech/openseek.html) that provides both SEEK and openBIS through Docker and Docker Compose.
  * A new UI for setting sharing permissions
    * Now displays a matrix for easier setting and viewing of individual permissions, replacing the pre-canned options 
    that weren't always that intuitive or logical.
    
![new_sharing_matrix](/images/release-notes/sharing-1.3.0.png){:.screenshot}

Details on how to use openBIS with SEEK is available in our [User Guide](/help/user-guide/openbis.html)
    
A full list of changes included in this release can be found in the [SEEK v1.3.0 release notes](release-notes-1.3.0.html).    

## Version 1.2.2

Release date: _March 3rd 2017_

Fixes a couple of issues caused by some missing CSS (Stylesheet) elements related to Samples. Although minor this
 affected some of the functional behaviour.
  
A full list of changes included in this release can be found in the [SEEK v1.2.2 release notes](release-notes-1.2.2.html).  

## Version 1.2.1

Release date: _February 21st 2017_

Small bug fix release to fix:

  * Crossref endpoint for DOI querying requires https://
  * Better DOI and Pubmed validation
  * Manual entry of publications currently disabled
  * Further improvements to authorization caching update speed and fix a small inconsistency with incomplete user registrations
  
A full list of changes included in this release can be found in the [SEEK v1.2.1 release notes](release-notes-1.2.1.html).  
    

## Version 1.2.0

Release date: _January 23rd 2017_

Large update with many new features and improvements, in particular a new approach to handling Sample information.

  * A major reimplementation and design of our support for Samples
    * Developed as part of our discussions within the [FAIRDOM-ELIXIR Samples Club](https://fair-dom.org/communities/samplesclub/), which was setup specifically to overcome problems with
     our old BioSamples
    * Flexible system that allows users to design their own Sample Type standards, which are associated with an 
    extractable spreadsheet template
      * Templates can be autogenerated, or Sample Types created from existing templates.
      * Sample Types contain a user designed set of attributes, and attribute types. 
      Validation is included to check a value matches its type, or if specified as ‘required’ a presence check is carried out.
      * Units can be optionally associated with a Sample Type attribute.
      * Sample Types can be interlinked, for example a Tissue Sample Type may link to a Patient Sample Type
      * Samples can be added to SEEK according to sample type. They can either be added manually, or many can be 
      extracted from an uploaded data file that originated from the associated template.
      * An attribute can be linked to a controlled vocabulary which enforces a set of values. 
      This also puts in place future support for CV’s from standard ontologies.
    * Assays were updated to now represent the first of many future processes, which can receive and produce sets of samples. 
    UI improvements were made to support easily associating many samples to an assay in at once. 
    A Process describes the changes a Sample may go through.
    * This new framework now has possibility to support the SampleTab standard, allowing SEEK to deposit to the EBI Biosamples registry    
    * A more flexible approach to handling Samples was an important requirement for full openBIS integration.
    * It is a framework that can be built upon and enhanced according to user needs in future versions.
    * There is documentation available in our [SEEK Samples User Guide](/help/user-guide/samples.html)
  * An improved Graphical and interactive ISA graph viewer. It now contains all details but expands as the user interacts 
  with it, avoiding the problem of over-complex graphs. A tree view is also now available to navigate the graph, 
  which includes the Programmes and Projects. A full view of the graph is available if necessary.
  * Authorization speedup. A significant improvement in speed and scale when updating the permissions of an item, 
  or a person changing state (e.g. to a  new role or project). For performance reasons authorization is cached, which 
  needs updating when a state changes. This resulted in a noticeable delay observed between users when permissions are changed 
  (as a background task updates the cache), sometimes causing confusion. This delay has now been significantly reduced, 
  and the delay is not dependent on the number of items.
  * Support for [Docker](https://docker.com), along with documentation. Docker images are automatically built for
   different versions and can be run either as a single container or multiple micro-services split across different containers. 
  Handles upgrades and persistent data. Docker allows SEEK to be setup and run with a single command. This our expected 
  approach to simple packaging of SEEK with openBIS.
    * Documentation on using SEEK with Docker is available in our [Docker Guide](/tech/docker.html)
  * A Project administrator may now specify the default license for their project which is automatically selected when creating a new item, but can be changed by the user if necessary.
  * Improved usability of adding new Publications from a DOI or PubmedID
  * Arbitrary URL schemes for remote files, that can be handled outside of SEEK. For example, and scp:// url could be 
  provided for and openSSH based resource
  * Storage metrics in one place available to SEEK administrator, split by Project and Programme. 
  Provides a single place to monitor storage rather than checking each Project page.  


A full list of changes included in this release can be found in the [SEEK v1.2.0 release notes](release-notes-1.2.0.html).


## Version 1.1.2

Release date: _September 30th 2016_

Fixes and small improvements, in particular:

  * A new My Items page, available from the account menu, which gives quick access to your own items
  * Fix to browsing text files, which was a particular problem for CSV and TSV files
  * Models simulation page can now be shared as a URL by copying from the browser.
  * Fix to include creators of Investigations, Studies and Assays in related items page

Small fixes and minor improvements - for full details see [SEEK v1.1.2 release notes](release-notes-1.1.2.html)

## Version 1.1.1

Release date: _June 21st 2016_

Small fixes and minor improvements - for full details see [SEEK v1.1.1 release notes](release-notes-1.1.1.html)

## Version 1.1.0

Release date: _June 15th 2016_

  * New icons and front page changes - in particular
      * New and improved SEEK logo - [https://goo.gl/NeALVA](https://goo.gl/NeALVA)
      * New default avatars for Project and Institution
      * New logos for Investigation, Study and Assays
      * New logos badges for the different roles
  * Support for Programmes to define funding codes
  * Licensing of assets. Existing assets will default to 'No License'. For more information please visit [Licenses](/help/user-guide/licenses.html)
  * Ability to publish and create Research Object snapshots for Studies and Assays, along with assigning a DOI. Previously only the larger Investigation package was supported
  * Display storage usage information for Programmes and Projects, visible to administrators.

A full list of changes included in this release can be found in the [SEEK v1.1.0 release notes](release-notes-1.1.0.html).


## Version 1.0.3

Release date: _April 1st 2016_

Upgrade fix that avoids a possible error in some cases when upgrading from a fresh 0.23.0 version of SEEK.

## Version 1.0.2

Release date: _February 9th 2016_

Patch release with some minor improvements and bug fixes, in particular

  * Corrected the information sent to project administrators when a new person signs up
  * Removed some redundant pages
  * Fix to application status report page for monitoring
  * ORCiD only mandatory during registration, not when creating profiles (if this configuration is turned on)

A full list of changes included in this release can be found in the [SEEK v1.0.2 release notes](release-notes-1.0.2.html).

## Version 1.0.1

Release date: _December 15th 2015_

Patch release with a couple of bugfixes.

  * Fixed the back-button after search
  * Prevent email password being auto filled by browser

Also added support to start easily and safely adding links to help pages in user guide.

A full list of changes included in this release can be found in the [SEEK v1.0.1 release notes](release-notes-1.0.1.html).

## Version 1.0.0

Release date: _December 8th 2015_

### Self management of Programmes and Projects

* Standard users can create their own Programmes.
  * This feature can be turned off by a SEEK administrator if not required.
  * An administrator is required to approve the created Programme.
* The creator of Programme can administer it, or allow somebody else to administer it.
* A programme administrator can create Organisms.
* Improvement to roles
  * Project manager becomes Project administrator.
  * Asset manager becomes Asset Housekeeper - and can now only manage assets for those who have been flagged as leaving a project.
  * Gatekeeper now becomes Asset Gatekeeper.
  * Introduced Programme administrator, who can create and projects and become their administrator or assign somebody else as an administrator.
  * _Roles will be fully documented in more detail in the near future_.
* A project administrator can flag somebody as having left a project.
* Better and easier management of project members and roles.

### Investigation Snapshots and publication

* Support for creating a [Research Object](https://www.researchobject.org/) for an Investigation to form a *Snapshot*.
  * This allows an Investigation to be frozen in time for publication, whilst allowing it to continue to change in the future.
  * Support for easily and quickly making a full Investigation publically available.
* A DOI can be generated and associated with an Investigation Snapshot.
* If configured, a snapshot can easily be pushed to [Zenodo](https://zenodo.org/).

### Improved support for remote and large content

* Presentations added as Slide share or Youtube links will now be rendered within SEEK.
  * This introduces a rendering framework that makes it easier to add new renderers and in the future make it easier for 3rd party developers to contribute renderers.
* Improved handling of remote and of large content.

### Biosamples

* Biosample support has been deprecated and disabled.
* Biosamples will be improved and reimplemented as our next major feature change.
* Biosamples can be re-enabled by an administrator.
* If you currently use the Biosamples that was available in SEEK please [contact us](/contacting-us.html).

### Help pages link

* Help pages can now be hosted externally and an administrator can point to the source of them.
* From past experience, we find it much easier to maintain and update our own Help pages and documentation outside of SEEK, allowing us to expand and improve on them between releases.
* Our documentation will now be published and maintained using GitHub pages making it easier to maintain between versions and receive [Contributions](/contributing.html).
* Internal help pages are currently still available, but could be deprecated in a future release. If you edit your own internal pages please [contact us](/contacting-us.html).

### Miscellaneous

* Improvements to ISA graph rendering.
* Better reporting of the source of error, if an error occurs with a 3rd party service integration.
* [ORCiD](https://orcid.org/) field can be made mandatory during registration.
* File extensions and urls are indexed for search.
* [Imprint/Impressum](https://en.wikipedia.org/wiki/Impressum) support.



A full detailed list of changes included in this release can be found in the [SEEK v1.0.0 release notes](release-notes-1.0.0.html).

[//]: <>## Previous releases

[//]: <>For previous releases please visit our [Earlier Changelogs](https://seek4science.org/changes).
