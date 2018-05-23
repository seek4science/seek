A **Model** is a computer model of a biological or biochemical network or process.Some **Models** may be simulated using the JWSOnline system.

**Although models are versioned, this is out of scope for the current release of the API.**

A **Model** has the following associated information:

* **The title of the Model**
* **The specification for the [ContentBlobs](#section/ContentBlob) in the Model**
* **References to the [Projects](#tag/projects) documented**
* A string containing a list of tags for the **Model**
* A description of the **Model**
* The [**License**](#section/Licence) applied to the **Model**
* The sharing [**Policy**](#section/Policy) applied to the **Model**
* A string listing other creators of the **Model**
* A string specifying the **Model** type
* A string specifying the **Model** format
* A string specifying the execution environment of the **Model**
* References to the [**People**](#tag/people) who wrote the **Model**
* References to the [**Assays**](#tag/assays) associated with the **Model**
* References to the [**Publications**](#tag/publications) associated with the **Model**

A response for a **Model** such as that for a [**Create**](#tag/create), [**Read**](#tag/read) or [**Update**](#tag/update) includes the additional information

* ** An array of the versions of the Model**
* ** A number indicating the latest version**
* ** The time when the Model was created**
* ** The last time the Model was updated**
* A reference to the [**Person**](#tag/people) who submitted the **Model**
* References to the [**Investigations**](#tag/investigations) associated with the **Model**
* References to the [**Studies**](#tag/studies) associated with the **Model**
