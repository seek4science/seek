<a name="sampleTypes"></a>A **SampleType** is a definition of the information that is held about a physical or virtual sample.

* The **title** of the SampleType, which corresponds the the **title** attribute
* References to the <a href="#projects">Projects</a> relevant to the **SampleType**
* An array of strings containing a list of **tags** for the **SampleType**
* A string providing a **description** of the **SampleType**
* An array of **Sample Attributes**, including their <a href="#sampleAttributeTypes">Sample Attribute Type</a> contained in this **SampleType**




A response for a **SampleType** such as that for a <a href="#create">**Create**</a>, <a href="#read">**Read**</a> or <a href="#update">**Update**</a> includes the additional information

* The time when the **SampleType** was **created**
* The last time the **SampleType** was **updated**
* A references to the **Submitter**</a> who created the **SampleType**  
* References to the <a href="#people">**People**</a> who created the **SampleType**
* References to the <a href="#samples">**Samples**</a> built from this **SampleType**

SampleType's contain the attribute **sample_attributes** which contains information about the attributes associated with the 
SampleType. These attributes also link to the **sample_attribute_type**. The full list of 
attribute types registered with the system can be found using the <a href="#operation/listSampleAttributeTypes">listSampleAttributeTypes</a> operation.

When creating or updating and wishing to specify the **sample_attribute_type**, either it's **id** or unique **title** can be used.

When updating a SampleType, a **sample_attribute** can be updated by specifying it's **id**. Without the **id**, a new attribute will be added.
Any **sample_attribute** not described in the payload will be left alone and unchanged. To remove an attribute, specify its
**id** and also set **_destroy** to be true.
