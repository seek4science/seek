A **Presentation** is a presentation about one or more [**Projects**](#tag/projects).

**Although presentations are versioned, this is out of scope for the current release of the API.**

A **Presentation** has the following associated information:

* **The title of the Presentation**
* **The specification for the [ContentBlobs](#section/ContentBlob) in the Presentation**
* **References to the [Projects](#tag/projects) documented**
* A string containing a list of tags for the **Presentation**
* A description of the **Presentation**
* The [**License**](#section/Licence) applied to the **Presentation**
* The sharing [**Policy**](#section/Policy) applied to the **Presentation**
* A string listing other creators of the **Presentation**
* References to the [**People**](#tag/people) who wrote the **Presentation**
* References to the [**Assays**](#tag/assays) associated with the **Presentation**
* References to the [**Publications**](#tag/publications) associated with the **Presentation**
* References to the [**Events**](#tag/events) associated with the **Presentation**

A response for a **Presentation** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* ** An array of the versions of the Presentation**
* ** A number indicating the latest version**
* ** The time when the Presentation was created**
* ** The last time the Presentation was updated**
* A reference to the [**Person**](#tag/people) who submitted the **Presentation**
* References to the [**Investigations**](#tag/investigations) associated with the **Presentation**
* References to the [**Studies**](#tag/studies) associated with the **Presentation**