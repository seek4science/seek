An **Assay** describes a particular experiment. It allows you to associate [**DataFiles**](#tag/dataFiles), [**SOPs**](#tag/sops) and [**Models**](#tag/models) together as well as describing the type of **Assay** and any technology required to perform the experiment.

An **Assay** has the following associated information:

* **The title of the Assay**
* A description of the **Assay**
* A string listing other creators of the **Assay**
* A string containing the abbreviated form of the kind of **Assay** - normally *EXP* for experimental or *MOD* for modelling
* A URI to the type of **Assay** resolving to an entry in the [JERM ontology](http://www.mygrid.org.uk/ontology/JERMOntology)
* A URI to the technology used in the **Assay** resolving to an entry in the [JERM ontology](http://www.mygrid.org.uk/ontology/JERMOntology)
* The sharing [**Policy**](#section/Policy) of the **Assay**
* References to the [**People**](#tag/people) who created the **Assay**
* A singleton reference to the [**Study**](#tag/studies) which the **Assay** is part of
* References to [**Publications**](#tag/publications) about the **Assay**
* References to [**DataFiles**](#tag/dataFiles) that belong to the **Assay**
* References to [**Documents**](#tag/documents) that belong to the **Assay**
* References to [**Models**](#tag/models) that belong to the **Assay**
* References to [**Sops**](#tag/sops) that belong to the **Assay**
* References to the [**Organisms**](#tag/organisms) studied in the **Assay**

A response for an **Assay** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* A singleton reference to the [**Investigation**](#tag/investigations) which the **Assay** is part of
* References to the [**Projects**](#tag/projects) that indirectly contain the **Assay**





