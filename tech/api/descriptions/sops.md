**SOPs** are standard operating procedures which describe the protocol required to reproduce an [**Assay**](#tag/assays). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant **SOPs** can be linked directly to the [**Assay**](#tag/assays).

**Although SOPs are versioned, this is out of scope for the current release of the API.**

A **SOP** has the following associated information:

* **The title of the SOP**
* **The specification for the [ContentBlobs](#section/ContentBlob) in the SOP**
* **References to the [Projects](#tag/projects) relevant to the SOP**
* A string containing a list of tags for the **SOP**
* A description of the **SOP**
* The [**License**](#section/Licence) applied to the **SOP**
* The sharing [**Policy**](#section/Policy) applied to the **SOP**
* A string listing other creators of the **SOP**
* References to the [**People**](#tag/people) who wrote the **SOP**
* References to the [**Assays**](#tag/assays) relevant to the SOP

A response for a **SOP** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* ** An array of the versions of the SOP**
* ** A number indicating the latest version**
* ** The time when the SOP was created**
* ** The last time the SOP was updated**
* A reference to the [**Person**](#tag/people) who submitted the **SOP**
* References to the [**Investigations**](#tag/investigations) associated with the **SOP**
* References to the [**Studies**](#tag/studies) associated with the **SOP**
* References to the [**Publications**](#tag/publications) associated with the **SOP**

