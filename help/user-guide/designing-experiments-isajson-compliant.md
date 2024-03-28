---
title: SEEK User Guide - Designing an ISA-JSON compliant experiment
layout: page
---

# Designing an ISA-JSON compliant experiment
The [ISA metadata framework](https://isa-specs.readthedocs.io/en/latest/isamodel.html) requires the description (metadata) of different types of samples, namely Study Sources, Study Samples and Assay Samples. This description is based on customisable Experiment Sample Templates and includes the linking of applied Protocols. Follow the link for an overview about [ISA-JSON compliant experiments](isa-json-compliant-experiment.html).

In the context of an ISA-JSON compliant experiment, we use the terms ISA Investigation, ISA Study, and ISA Assay when referring to Investigation, Study, and Assay, respectively.

## 1. Creating an ISA Investigation
Select 
* Create Investigation from header menu bar.
* Alternatively, in Experiment View, select the Design Investigation button at the top right corner  

Fill out the provided form, check the option for "Make Investigation compliant to ISA-JSON schemas?" and then click the 'Create' button.

![select isajson compliance](/images/user-guide/isajson-compliance/select_isajson_compliance.png){:.screenshot}


## 2. Creating an ISA Study
ISA Study can only be associated to an ISA Investigation. It is not possible to associate an ISA Study to an Investigation which is not ISA-JSON compliant.

To start designing an ISA Study within the Investigation in Experiment View, select the Investigation and then select the "Design Study" button at the top right corner.

Fill out the provided form as explained below.


## 2.1 Design a Sources table for Study Sources
The Sources table can be used to register metadata about Study Sources material.
* Biological material and its origin or provenance
* Environmental and/or experimental conditions of the Sources in the Study
* Experimental groups of the Sources
* Observation units
* Experimental factor(s), confounding variables, covariates, events, comments etc
* Any other relevant information about the Sources in the Study

The Study Sources table is a Sample Type associated with the Study and can only be accessed through the Study interface. The Study Sources table can only be created starting from an existing Experiment Sample Templates.

### 2.1.1 Choose one Experiment Sample Template

* Choose one Experiment Sample Templates by clicking on "Existing Experiment Sample Templates" button.

![create isastudy source 1](/images/user-guide/isajson-compliance/create_isastudy_source_1.png){:.screenshot}

* Filter existing Experiment Sample Templates based on:
  * the repository that will store metadata about your Study Sources (e.g. ENA, ArrayExpress or your institutional repository). Select "Project specific templates" if you want to use a template made for or by a specific Project
  * organism

![create isastudy source 2](/images/user-guide/isajson-compliance/create_isastudy_source_2.png){:.screenshot}

* Choose a template from the resulting dropdown menu.
* Select "Apply".
* Give a Title to the Study Sources table.

### 2.1.2 Customise the Study Sources table

The Attributes table can be used to customise the Study Sources table. However, be aware that applying changes may compromise the compliance to the original template.

* If you want to add new attributes of your choice to your Sources table, select “Add new attribute” button.
* Fill out the mandatory and optional fields. Note that for ISA-JSON compliant Experiments, the ISA Tag is a mandatory field.
* For ISA tag, select "source_characteristic". Note that selecting "source" would generate an error since a "source" is already selected in the starting template.

![create isastudy source 3](/images/user-guide/isajson-compliance/create_isastudy_source_3.png){:.screenshot}

## 2.2 Link the sampling Protocol 
Select Protocols already registered in the platform that describe the used method or procedure (SOP) used to collect Samples from Sources in your Study (Samples collection protocol). See how to [create an SOP](adding-assets.html) in SEEK.

## 2.3 Design a Samples table for Study Samples

Follow the same steps described for designing the Study Sources table to create and customise the Study Samples table.

## 2.4 Visualise ISA Study
Upon creation, the newly designed ISA Study will appear in the tree view on the left sidebar, in Experiment View. Follow the link to know more about [Experiment View](viewing-project-in-single-page.html).

## 3. Adding Sources to ISA Study
After you have designed the Sources table, you can then start by creating and describing your Study Sources according to the designed table.

Follow the link to know how to [create samples in ISA-JSON compliant experiments](create-sample-isajson-compliant.html), including [Study Sources](create-sample-isa-json-compliant.html#create-study-sources).

## 4. Adding Samples to ISA Study

Follow the link to know how to [create samples in ISA-JSON compliant experiments](create-sample-isajson-compliant.html), including [Study Samples](create-sample-isajson-compliant.html#create-study-samples).

## 5. Creating an Assay Stream

* Select an ISA-JSON compliant Study, then click on "Design Assay Stream" button at the top right corner of the page.
* Fill out the form and click "Create". After creation, sharing permissions can be managed.
  * Assay position: Assay position determines the order in which Assay Streams are visualized in the tree view relative to each other.

## 6. Creating an ISA Assay

* Select an Assay Stream, then click on "Design Assay" button at the top right corner of the page.
* Fill out the provided form as explained below.

## 6.1 Link the sampling Protocol 
Select Protocols already registered in the platform that describe the used method or procedure (SOP) applied to the Assay. See how to [create an SOP](adding-assets.html) in SEEK.

## 6.2 Design a Samples table for Assay

The Assay Samples table can be used to register metadata about Assay's outputs (other material or data file).
* The method, the protocol and its parameters (parameter value) applied to the Assay to generate the Assay’s outputs.
* Any relevant characteristics of the Assay’s outputs (other material characteristic or data file comment), from sample’s amount and quality to storage of each physical tube in a laboratory or of each digital data file in a file storage system.

The Assay Samples table is a Sample Type associated with the Assay and can only be accessed through the Assay interface. The Assay Samples table can only be created starting from an existing Experiment Sample Templates.

### 6.2.1 Choose one Experiment Sample Template

* Choose one Experiment Sample Templates by clicking on "Existing Experiment Sample Templates" button.

* Filter existing Experiment Sample Templates based on:
  * the repository that will store metadata about your Study Sources (e.g. ENA, ArrayExpress or your institutional repository). Select "Project specific templates" if you want to use a template made for or by a specific Project
  * ISA Level
    * assay - material: if the output samples of the assay are physical materials
    * assay - data file: if the output of the assays are digital data files
  * organism

![create isaassay 2](/images/user-guide/isajson-compliance/create_isaassay_2.png){:.screenshot}

* Choose a template from the resulting dropdown menu.
* Select "Apply".
* Give a Title to the Assay Samples table.

### 6.2.2 Customise the Assay Samples table

The Attributes table can be used to customise the Assay Samples table. However, be aware that applying changes may compromise the compliance to the original template.

* If you want to add new attributes of your choice to your Samples table, select “Add new attribute” button.
* Fill out the mandatory and optional fields. Note that for ISA-JSON compliant Experiments, the ISA Tag is a mandatory field.
* For ISA tag, select 
  * in case of ISA Level "assay - material": "other_material_characteristic" or "parameter_value";
  * in case of ISA Level "assay - data file": "data_file_comment" or "parameter_value";
  
  Note that selecting any other options would generate an error since other options are already selected in the starting template.

![create isaassay 3](/images/user-guide/isajson-compliance/create_isaassay_3.png){:.screenshot}

## 6.3 Visualise ISA Assay
Upon creation, the newly designed ISA Assay will appear in the tree view on the left sidebar, in Experiment View. Follow the link to know more about [Experiment View](viewing-project-in-single-page.html).
    
## 7. Adding samples to ISA Assay
Follow the link to know how to [create samples in ISA-JSON compliant experiments](create-sample-isajson-compliant.html), including [Assay Samples](create-sample-isajson-compliant.html#create-assay-samples).
