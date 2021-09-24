A **Sample** has the following associated information:

* **The title of the Sample, which corresponds the the title attribute**
* **References to the <a href="#projects">Projects</a> relevant to the Sample**
* A string containing a list of tags for the **Sample**
* The sharing <a href="#Policy">**Policy**</a> applied to the **Sample**
* A string listing other creators of the **Sample**
* The **attribute map**, containing the attribute values for the **Sample** _(see below)_ 
* References to the <a href="#people">**People**</a> who created the **Sample**
* References to the <a href="#assays">**Assays**</a> relevant to the **Sample**
* References to the <a href="#data_files">**Data files**</a> relevant to the **Sample**
* A references to the <a href="#sampleTypes">**Sample type**</a> relevant to the **Sample**

A response for a **Sample** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* The time when the **Sample** was **created**
* The last time the **Sample** was **updated**
* A references to the **Submitter**</a> who created the **Sample**

**Samples** differ slightly from other payloads due to the flexible nature of the attributes and their values,
which are handled through the **attribute_map** property.

The **attribute_map** is a hash containing key/value pairs, where the key relates to the attribute title, which can be
found by looking at the corresponding <a href="#sample_types">**Sample type**</a>. To set the attribute value, the key must
match this title. 
When doing a patch, individual attributes can be updated without missing from the map, those will retain their current value.
The values will be validated against the corresponding **sample_attribute**.

It is possible to create a **Sample** together with its attribute values - infact it must do where
attributes are required.
