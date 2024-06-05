<a name="studies"></a>A **Study** is a series of experiments (or <a href="#assays">**Assays**</a> ) which can be combined to answer a particular biological question. These experiments might be a series of the same type of <a href="#assays">**Assay**</a> (for example, microarrays for different conditions), or they may be a collection of different types of <a href="#assays">**Assay**</a> (e.g. a combination of array and mass spec measurements).

A **Study** has the following associated information:

* **The title of the Study**
* A description of the **Study**
* A string listing experimentalists of the **Study**
* A string listing other creators of the **Study**
* A string containing the id of the <a href="#people">**Person**</a> responsible for the **Study**
* The sharing <a href="#Policy">**Policy**</a> of the **Study**
* References to the <a href="#people">**People**</a> who created the **Study**
** A reference to the <a href="#investigations">Investigation</a> containing the Study**
* References to <a href="#publications">**Publications**</a> about the **Study**

A response for a **Study** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* A reference to the <a href="#people">**Person**</a> who registered (submitted) the **Study** into SEEK
* References to the <a href="#projects">**Projects**</a> that indirectly contain the **Study**
* References to the <a href="#assays">**Assays**</a> that belong to the **Stuady**
* References to <a href="#dataFiles">**DataFiles**</a> that belong to the **Study**
* References to <a href="#documents">**Documents**</a> that belong to the **Study**
* References to <a href="#models">**Models**</a> that belong to the **Study**
* References to <a href="#sops">**Sops**</a> that belong to the **Study**
* References to <a href="#publications">**Publications**</a> that belong to the **Study**

**Studies** have support for [Extended Metadata](/api#section/Extended-Metadata)



