<a name="presentations"></a>A **Presentation** is a presentation about one or more <a href="#projects">**Projects**</a>.

**Although presentations are versioned, this is out of scope for the current release of the API.**

A **Presentation** has the following associated information:

* **The title of the Presentation**
* **The specification for the <a href="#ContentBlob">ContentBlobs</a> in the Presentation**
* **References to the <a href="#projects">Projects</a> documented**
* A string containing a list of tags for the **Presentation**
* A description of the **Presentation**
* The <a href="#License">**License**</a> applied to the **Presentation**
* The sharing <a href="#Policy">**Policy**</a> applied to the **Presentation**
* A string listing other creators of the **Presentation**
* References to the <a href="#people">**People**</a> who wrote the **Presentation**
* References to the <a href="#assays">**Assays**</a> associated with the **Presentation**
* References to the <a href="#publications">**Publications**</a> associated with the **Presentation**
* References to the <a href="#events">**Events**</a> associated with the **Presentation**

A response for a **Presentation** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* ** An array of the versions of the Presentation**
* ** A number indicating the latest version**
* ** The time when the Presentation was created**
* ** The last time the Presentation was updated**
* A reference to the <a href="#people">**Person**</a> who submitted the **Presentation**
* References to the <a href="#investigations">**Investigations**</a> associated with the **Presentation**
* References to the <a href="#studies">**Studies**</a> associated with the **Presentation**

**Presentations** have support for [Extended Metadata](/api#section/Extended-Metadata)