<a name="documents"></a>A **Document** is any documentation that describes an <a href="#investigations">**Investigation**</a>, <a href="#studies">**Study**</a> or <a href="#assays">**Assay**</a>. The content of a **Document** is descriptive and it must not contain any data that is consumed or produced by an <a href="#assays">**Assay**</a>.

**Although documents are versioned, this is out of scope for the current release of the API.**

A **Document** has the following associated information:

* **The title of the Document**
* **The specification for the <a href="#ContentBlob">ContentBlobs</a> in the Document**
* **References to the <a href="#projects">Projects</a> documented**
* A string containing a list of tags for the **Document**
* A description of the **Document**
* The <a href="#License">**License**</a> applied to the **Document**
* The sharing <a href="#Policy">**Policy**</a> applied to the **Document**
* A string listing other creators of the **Document**
* References to the <a href="#people">**People**</a> who wrote the **Document**
* References to the <a href="#assays">**Assays**</a> documented

A response for a **Document** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* ** An array of the versions of the Document**
* ** A number indicating the latest version**
* ** The time when the Document was created**
* ** The last time the Document was updated**
* A reference to the <a href="#people">**Person**</a> who submitted the **Document**
* References to the <a href="#investigations">**Investigations**</a> associated with the **Document**
* References to the <a href="#studies">**Studies**</a> associated with the **Document**
* References to the <a href="#publications">**Publications**</a> associated with the **Document**

**Documents** have support for [Extended Metadata](/api#section/Extended-Metadata)
















