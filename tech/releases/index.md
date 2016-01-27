---
title: SEEK releases
layout: page
---

# SEEK Releases

Latest version - {{ site.current_seek_version }}

## Version 1.0.1

Release date: _(December 15th 2015)_

Patch release with a couple of bugfixes.

  * Fixed the back-button after search
  * Prevent email password being auto filled by browser

Also added support to start easily and safely adding links to help pages in user guide.

A full list of changes included in this release can be found in the [SEEK v1.0.1 release notes](release-notes-1.0.1.html).

## Version 1.0.0

Release date: _(December 8th 2015)_

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

* Support for creating a [Research Object](http://www.researchobject.org/) for an Investigation to form a *Snapshot*.
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
* [ORCiD](http://orcid.org/) field can be made mandatory during registration.
* File extensions and urls are indexed for search.
* [Imprint/Impressum](https://en.wikipedia.org/wiki/Impressum) support.



A full detailed list of changes included in this release can be found in the [SEEK v1.0.0 release notes](release-notes-1.0.0.html).

## Previous releases

For previous releases please visit our [Earlier Changelogs](http://seek4science.org/changes).
