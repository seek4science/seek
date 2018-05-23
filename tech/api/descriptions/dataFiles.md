A **dataFile** can be any file containing data relevant to the [**Assay**](#tag/assays) (raw data, processed data, calibration information etc). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc).

**Although dataFiles are versioned, this is out of scope for the current release of the API.**

A **DataFile** has the following associated information:

* **The title of the DataFile**
* **The specification for the [ContentBlobs](#section/ContentBlob) in the DataFile**
* **References to the [Projects](#tag/projects) documented**
* A string containing a list of tags for the **DataFile**
* A description of the **DataFile**
* The [**License**](#section/Licence) applied to the **DataFile**
* The sharing [**Policy**](#section/Policy) applied to the **DataFile**
* A string listing other creators of the **DataFile**
* References to the [**People**](#tag/people) who wrote the **DataFile**
* References to the [**Assays**](#tag/assays) associated with the **DataFile**
* References to the [**Publications**](#tag/publications) associated with the **DataFile**
* References to the [**Events**](#tag/events) associated with the **DataFile**

A response for a **DataFile** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* ** An array of the versions of the DataFile**
* ** A number indicating the latest version**
* ** The time when the DataFile was created**
* ** The last time the DataFile was updated**
* A reference to the [**Person**](#tag/people) who submitted the **DataFile**
* References to the [**Investigations**](#tag/investigations) associated with the **DataFile**
* References to the [**Studies**](#tag/studies) associated with the **DataFile**



