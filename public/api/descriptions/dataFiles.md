<a name="dataFiles"></a>A **dataFile** can be any file containing data relevant to the <a href="#assays">**Assay**</a> (raw data, processed data, calibration information etc). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc).

**Although dataFiles are versioned, this is out of scope for the current release of the API.**

A **DataFile** has the following associated information:

* **The title of the DataFile**
* **The specification for the <a href="#ContentBlob">ContentBlobs</a> in the DataFile**
* **References to the <a href="#projects">Projects</a> documented**
* A string containing a list of tags for the **DataFile**
* A description of the **DataFile**
* The <a href="#License">**License**</a> applied to the **DataFile**
* The sharing <a href="#Policy">**Policy**</a> applied to the **DataFile**
* A string listing other creators of the **DataFile**
* References to the <a href="#people">**People**</a> who wrote the **DataFile**
* References to the <a href="#assays">**Assays**</a> associated with the **DataFile**
* References to the <a href="#publications">**Publications**</a> associated with the **DataFile**
* References to the <a href="#events">**Events**</a> associated with the **DataFile**

A response for a **DataFile** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* ** An array of the versions of the DataFile**
* ** A number indicating the latest version**
* ** The time when the DataFile was created**
* ** The last time the DataFile was updated**
* A reference to the <a href="#people">**Person**</a> who submitted the **DataFile**
* References to the <a href="#investigations">**Investigations**</a> associated with the **DataFile**
* References to the <a href="#studies">**Studies**</a> associated with the **DataFile**

**DataFiles** have support for [Extended Metadata](/api#section/Extended-Metadata)

