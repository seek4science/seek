<a name="sops"></a>**SOPs** are standard operating procedures which describe the protocol required to reproduce an <a href="#assays">**Assay**</a>. They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant **SOPs** can be linked directly to the <a href="#assays">**Assay**</a>.

**Although SOPs are versioned, this is out of scope for the current release of the API.**

A **SOP** has the following associated information:

* **The title of the SOP**
* **The specification for the <a href="#ContentBlob">ContentBlobs</a> in the SOP**
* **References to the <a href="#projects">Projects</a> relevant to the SOP**
* A string containing a list of tags for the **SOP**
* A description of the **SOP**
* The <a href="#License">**License**</a> applied to the **SOP**
* The sharing <a href="#Policy">**Policy**</a> applied to the **SOP**
* A string listing other creators of the **SOP**
* References to the <a href="#people">**People**</a> who wrote the **SOP**
* References to the <a href="#assays">**Assays**</a> relevant to the SOP

A response for a **SOP** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* An array of the versions of the **SOP**
* A number indicating the latest **version**
* The time when the SOP was **created**
* The last time the SOP was **updated**
* A reference to the <a href="#people">**Person**</a> who submitted the **SOP**
* References to the <a href="#investigations">**Investigations**</a> associated with the **SOP**
* References to the <a href="#studies">**Studies**</a> associated with the **SOP**
* References to the <a href="#publications">**Publications**</a> associated with the **SOP**

**SOPs** have support for [Extended Metadata](/api#section/Extended-Metadata)
