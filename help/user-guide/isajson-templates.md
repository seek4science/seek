---
title: SEEK User Guide - Experiment Sample Templates
layout: page
---

# For system administrator

## JSON upload via Server admin panel
If ISA-JSON compliance feature is enabled, an option appears in the Server admin panel to upload instance-wide Experiment Sample Templates, compliant to ISA-JSON schemas.

The Experiment Sample Templates must be in .json format and comply to the expected specification.

![experiment view](/images/user-guide/isajson-compliance/serveradmin-expsampletemplate-jsonupload.png){:.screenshot}

## ISA minimal starter template
When the ISA-JSON compliance feature is enabled in the platform, it is recommended to use the "ISA minimal starter template" as the starting point for creating any new Experiment Sample Template. One ISA minimal starter template is provided for each ISA Level with the feature.

<!--where to find them, specification-->

# For project members

ISA-JSON compliant experiments can only be created based on [Experiment Sample Templates](isa-json-compliant-experiment.html#experiment-sample-templates). These templates are essential for designing the descriptions of ISA Study Sources, Samples, and Assay Samples (see [samples in ISA-JSON compliant experiments](create-sample-isajson-compliant.html)).

Project members have the capability to create Experiment Sample Templates for their laboratory or research project. These templates can be shared among Projects and Programmes on the platform via granular [sharing permissions](general-attributes.html#sharing), allowing other project members to utilize them for designing their experiments.

## Create Experiment Sample Templates

1. From the header menu bar, select "Create" and then "Experiment Sample Templates" under the Experiments section.
2. Fill out the mandatory and optional fields.
3. Under "Template Information", click on the "Choose from existing templates" button.
4. Choose the template to start from based on its [characteristics](isa-json-compliant-experiment.html#experiment-sample-template-characteristics). After selecting the parameters listed below, choose the templates you wish to use as a basis, and then click "Apply".
* The repository you want your template to comply to (e.g. ENA, ArrayExpress or your institutional repository). Select "Project specific templates" if you want to use a template made for or by a specific Project.
* The ISA Level you want your template to be applicable for.
* The Organism.
5. Customise the template by usig the Attributes table. However, be aware that applying changes may compromise the compliance to the original template.
* If you want to add new attributes of your choice to your new template, select “Add new attribute” button.
* Fill out the mandatory and optional fields. Note that for ISA-JSON compliant Experiments, the ISA Tag is a mandatory field.
* For ISA tag, note that the following tags can only be present once in a template: source, sample, other_material, data_file, protocol. One of these tags is already present in existing templates, so select one of the following as ISA tags: source_characteristic, parameter_value, sample_characteristic, other_material_characteristic, data_file_comment.
6. Select "Create".