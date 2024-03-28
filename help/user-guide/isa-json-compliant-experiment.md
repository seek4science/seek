---
 title: SEEK User Guide - ISA-JSON compliant Experiment
 layout: page
---

# ISA-JSON compliant Experiment

When using ISA-JSON compliant experiment to organise your Project, you structure your research according to the [ISA metadata framework](https://isa-specs.readthedocs.io/en/latest/isamodel.html), so that it can be exported as ISA-JSON. When referring to Investigation, Study, and Assay within an ISA-JSON compliant experiment, we use the terms ISA Investigation, ISA Study, and ISA Assay.

## ISA Investigation

In SEEK, an Investigation becomes an ISA-JSON compliant Investigation (or ISA Investigation) when the the option for "Make Investigation compliant to ISA-JSON schemas?" is selected.

![select isajson compliance](/images/user-guide/isajson-compliance/select_isajson_compliance.png){:.screenshot}

## ISA Study

ISA Study can only be associated to an ISA Investigation. It is not possible to associate an ISA Study to an Investigation which is not ISA-JSON compliant.

An ISA Study is a central unit that must contain the description (metadata) of:

1. *Source(s)* - the subjects or observation units under study (e.g. plants, mouse models, cultured cells, microorganisms).

2. *Protocol* - samples collection protocol, SOP or materials and methods describing the sampling process from Source (e.g. leaves harvesting, biopsy procedure, aliquoting).

3. *Sample(s)* - the physical material which results from the sampling protocol (e.g. leaves, biopsies, aliquotes).

## Assay Stream
An Assay Stream constitutes a structured sequence of sequential assays, interconnected through the flow of samples. Within an Assay Stream, the sample output of one assay serves as the input for the subsequent one. Each Assay Stream aligns with a single Assay in the ISA metadata framework. It is typically associated with one specific technology or technique, such as Metabolomics or Sequencing.

![assay stream](/images/user-guide/isajson-compliance/assaystream.png){:.screenshot}

### ISA Assay

An ISA Assay is in general the application of a protocol (SOP) to inputs that leads to the generation of outputs. Therefore, an ISA Assay must have Inputs, a Protocol and Outputs. An ISA Assay corresponds to one "process" in the ISA metadata framework. In an ISA Assay, every input must have at least one output (or more) and every output (Assay sample) must have at least one input (or more).

The outputs of an Assay can only be used as inputs by the next Assay in the same Assay Stream. In other words, the outputs of an Assay cannot be used as inputs in multiple Assays within the same Assay Stream.

1. The inputs can be defined as:
* existing *Sample(s)* created in the Study (e.g. leaves, biopsies, aliquotes). This applies to Assays directly performed on the Study samples;
* existing outputs of an Assay (Assay samples) that precedes the one you are creating in the same Assay Stream.

2. The Protocol can describe:
* an experimental step (e.g. nucleic acids extraction, library construction);
* a data (pre)processing step (e.g. data normalisation).

3. The outputs of an Assay (Assay samples), are samples that can be:
* physical materials (e.g. nucleic acids extracts, RNA libraries) generated from an experimental step;
* data files (e.g. files containing measurements, rawdata.fastq, processed data, reads.counts.txt).


# Experiment Sample Templates

Experiment Sample Templates act as blueprints to create Sample Types within ISA Studies and ISA Assays. The same Experiment Sample Template can be applied multiple times to create Sample Types in different ISA Studies or ISA Assays.

The ISA Study Sources, Samples and ISA Assay Samples tables are Sample Types associated with the ISA Study or ISA Assay and can only be accessed through the ISA Study or ISA Assay interface. The tables can only be created starting from an existing Experiment Sample Templates.

## Platform-wide and project specific Experiment Sample Templates

Experiment Sample Templates can be [provided by the platform administrator](isajson-templates.html#for-system-administrator) or created by Project members based on an existing template. Templates provided by the platform administrator are platform-wide (or instance-wide) and visible to every registered user. Project-specific Experiment Sample Templates created by Project members are subject to sharing permissions.

## Experiment Sample Template characteristics

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

## ISA minimal starter template

When the ISA-JSON compliance feature is enabled in the platform, it is possible to use the "ISA minimal starter template" as a starting point to create any Experiment Sample Template. One ISA minimal starter template for each ISA Level is provided with the feature.

# Samples in ISA-JSON compliant Experiments

In ISA-JSON compliant Experiments, samples must be created within a Sample Type derived from an Experiment Sample Template, associated with one ISA Studies or one ISA Assays.

The "level" of the Experiment Sample Template applied to generate a Sample Type within an ISA Study or ISA Assay determines the type of samples that will be created. Specifically, 
* ISA Study Source Template for Study Sources
* ISA Study Sample Template for Study Samples
* ISA material output Assay Template for material samples
* ISA data file Assay Template for digital data file samples

## Types of samples in ISA-JSON compliant Experiments

Study Source(s)
* Study Sources must be created within an ISA Study, using an Experiment Sample Template level "Study Source".
* Each Study Source must be the input of at least one Study Sample (or more) in the same ISA Study.

Study Sample(s)
* Study Samples must be created within an ISA Study, using an Experiment Sample Template level "Study Sample".
* Study Samples must be the outputs of a sampling protocol applied to ISA Study Sources, in the same Study.
* Each Study Sample must be the output of at least one Source (or more), in the same ISA Study.

Material output assay sample(s)
* Assay material samples must be created within an ISA Assay, using an Experiment Sample Template level "Assay - material".
* Assay material samples must be the outputs of a protocol applied to the inputs of the Assay.
* Each Assay Sample must have at least one input (or more). Inputs can be: 
  * Study Samples in the same ISA Study;
  * Assay samples from one preceding Assay, in the same Assay Stream.

Data file output assay sample(s)
Same as for material output assay sample(s), but for assays specifically designed to produce data files.

## Browsing samples by templates
[Browsing samples by templates](browsing.html#browsing-samples-by-experiment-sample-templates)

# ISA JSON export
[Export Experiments as ISA-JSON](exporting-experiments-as-isajson.html)

