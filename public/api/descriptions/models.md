<a name="models"></a>A **Model** is a computer model of a biological or biochemical network or process.Some **Models** may be simulated using the JWSOnline system.

**Although models are versioned, this is out of scope for the current release of the API.**

A **Model** has the following associated information:

* **The title of the Model**
* **The specification for the <a href="#ContentBlob">ContentBlobs</a> in the Model**
* **References to the <a href="#projects">Projects</a> documented**
* A string containing a list of tags for the **Model**
* A description of the **Model**
* The <a href="#License">**License**</a> applied to the **Model**
* The sharing <a href="#Policy">**Policy**</a> applied to the **Model**
* A string listing other creators of the **Model**
* A string specifying the **Model** type
* A string specifying the **Model** format
* A string specifying the execution environment of the **Model**
* References to the <a href="#people">**People**</a> who wrote the **Model**
* References to the <a href="#assays">**Assays**</a> associated with the **Model**
* References to the <a href="#publications">**Publications**</a> associated with the **Model**

A response for a **Model** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* ** An array of the versions of the Model**
* ** A number indicating the latest version**
* ** The time when the Model was created**
* ** The last time the Model was updated**
* A reference to the <a href="#people">**Person**</a> who submitted the **Model**
* References to the <a href="#investigations">**Investigations**</a> associated with the **Model**
* References to the <a href="#studies">**Studies**</a> associated with the **Model**

**Models** have support for [Extended Metadata](/api#section/Extended-Metadata)