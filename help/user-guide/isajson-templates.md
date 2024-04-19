---
title: SEEK User Guide - Experiment Sample Templates
layout: page
---
# Experiment Sample Templates

Experiment Sample Templates act as blueprints to create Sample Types within ISA Studies and ISA Assays and ensure that
the metadata collected conforms to community standards. The same Experiment Sample Template can be applied multiple times to create Sample Types in different ISA Studies or ISA Assays.

The ISA Study Sources, Samples and ISA Assay Samples tables are Sample Types associated with the ISA Study or ISA Assay and can only be accessed through the ISA Study or ISA Assay interface. The tables can only be created starting from an existing Experiment Sample Template.


An Experiment Sample Template must have the following specifications.
1. One ISA Level
   * Study Source
   * Study Sample
   * Assay material
   * Assay data file

2. One Repository name or SEEK Project
   * Repository or data archive (e.g. EBI databases)
   * SEEK Project (Project specific templates)

3. Organism: optional free text


## Platform-wide and project specific Experiment Sample Templates

Experiment Sample Templates can be provided by the platform administrator by uploading a json file (see below). Alternatively, they can be created by Project members based on an existing template. Templates provided by the platform administrator are platform-wide (or instance-wide) and visible to every registered user. Project-specific Experiment Sample Templates created by Project members are subject to sharing permissions.



### Creating Experiment Sample Templates as a project member

Project members have the capability to create Experiment Sample Templates for their laboratory or research project. These templates can be shared among Projects and Programmes on the platform via granular [sharing permissions](general-attributes.html#sharing), allowing other project members to utilize them for designing their experiments.


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


### JSON upload via Server admin panel [FOR SYSTEM ADMINISTRATORS]
If ISA-JSON compliance feature is enabled, an option appears in the Server admin panel to upload instance-wide Experiment Sample Templates, compliant to ISA-JSON schemas.

The Experiment Sample Templates must be in .json format and comply to the expected specification.

![experiment view](/images/user-guide/isajson-compliance/serveradmin-expsampletemplate-jsonupload.png){:.screenshot}


### ISA minimal starter template

Additionally, when the ISA-JSON compliance feature is enabled in the platform, an "ISA minimal starter template" is available which can be used as a starting point to create any Experiment Sample Template. One ISA minimal starter template for each ISA Level is provided.

<!--where to find them, specification-->