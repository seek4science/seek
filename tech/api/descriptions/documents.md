A **Document** is any documentation that describes an [**Investigation**](#tag/investigations), [**Study**](#tag/studies) or [**Assay**](#tag/assays). The content of a **Document** is descriptive and it must not contain any data that is consumed or produced by an [**Assay**](#tag/assays).

**Although documents are versioned, this is out of scope for the current release of the API.**

A **Document** has the following associated information:

* **The title of the Document**
* **The specification for the [ContentBlobs](#section/ContentBlob) in the Document**
* **References to the [Projects](#tag/projects) documented**
* A string containing a list of tags for the **Document**
* A description of the **Document**
* The [**License**](#section/Licence) applied to the **Document**
* The sharing [**Policy**](#section/Policy) applied to the **Document**
* A string listing other creators of the **Document**
* References to the [**People**](#tag/people) who wrote the **Document**
* References to the [**Assays**](#tag/assays) documented

A response for a **Document** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* ** An array of the versions of the Document**
* ** A number indicating the latest version**
* ** The time when the Document was created**
* ** The last time the Document was updated**
* A reference to the [**Person**](#tag/people) who submitted the **Document**
* References to the [**Investigations**](#tag/investigations) associated with the **Document**
* References to the [**Studies**](#tag/studies) associated with the **Document**
* References to the [**Publications**](#tag/publications) associated with the **Document**

















