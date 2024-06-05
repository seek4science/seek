<a name="projects"></a>A **Project** is an area of research carried out as part of a <a href="#programmes">**Programme**</a> and consisting of one or more <a href="#investigations">**Investigations**</a>.

**In the current version of the API, the <a href="#Policy">Policy</a> and the description of Project members and administrative roles does not work correctly.  This will be improved in future versions of the API.**

A **Project** has the following associated information:

* **The title of the Project**
* A reference to an avatar / logo for the **Project**
* A description of the **Project**
* A URI to a webpage about the **Project**
* A URI to the wiki of the **Project**
* The default <a href="#Policy">**Policy**</a> applied to objects belonging to the **Project**
* The default <a href="#License">**License**</a> applied to objects belonging to the **Project**

* References to the <a href="#programmes">**Programmes**</a> that the **Project** is part of
* References to the <a href="#organisms">**Organisms**</a> studied by the **Project**

A response for a **Project** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* References to <a href="#people">**People**</a> who work on the **Project**
* References to <a href="#institutions">**Institutions**</a> that are involved in the **Project**
* References to <a href="#investigations">**Investigations**</a> that are part of the **Project**
* References to <a href="#studies">**Studies**</a> that are part of the **Project**
* References to <a href="#assays">**Assays**</a> that are part of the **Project**
* References to <a href="#dataFiles">**DataFiles**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#documents">**Documents**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#models">**Models**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#sops">**Sops**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#publications">**Publications**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#presentations">**Presentations**</a> that belong to the <a href="#projects">**Project**</a>
* References to <a href="#events">**Events**</a> that are held by or attended by the <a href="#projects">**Project**</a>

**Projects** have support for [Extended Metadata](/api#section/Extended-Metadata)

