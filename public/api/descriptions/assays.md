<a name="assays"></a>An **Assay** describes a particular experiment. It allows you to associate <a href="#dataFiles">**DataFiles**</a>, <a href="#sops">**SOPs**</a> and <a href="#models">**Models**</a> together as well as describing the type of **Assay** and any technology required to perform the experiment.

An **Assay** has the following associated information:

* **The title of the Assay**
* A description of the **Assay**
* A string listing other creators of the **Assay**
* A string containing the abbreviated form of the kind of **Assay** - normally *EXP* for experimental or *MOD* for modelling
* A URI to the type of **Assay** resolving to an entry in the [JERM ontology](http://jermontology.org/ontology/JERMOntology)
* A URI to the technology used in the **Assay** resolving to an entry in the [JERM ontology](http://jermontology.org/ontology/JERMOntology)
* The sharing <a href="#Policy">**Policy**</a> of the **Assay**
* References to the <a href="#people">**People**</a> who created the **Assay**
* A singleton reference to the <a href="#studies">**Study**</a> which the **Assay** is part of
* References to <a href="#publications">**Publications**</a> about the **Assay**
* References to <a href="#dataFiles">**DataFiles**</a> that belong to the **Assay**
* References to <a href="#documents">**Documents**</a> that belong to the **Assay**
* References to <a href="#models">**Models**</a> that belong to the **Assay**
* References to <a href="#sops">**Sops**</a> that belong to the **Assay**
* References to the <a href="#organisms">**Organisms**</a> studied in the **Assay**

A response for an **Assay** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* A singleton reference to the <a href="#investigations">**Investigation**</a> which the **Assay** is part of
* References to the <a href="#projects">**Projects**</a> that indirectly contain the **Assay**

**Assays** have support for [Extended Metadata](/api#section/Extended-Metadata)



