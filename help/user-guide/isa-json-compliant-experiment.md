---
 title: SEEK User Guide - ISA-JSON compliant Experiment
 layout: page
---

# ISA-JSON compliant Experiment

When using ISA-JSON compliant experiments to organise your Project, you structure your research fully according to the [ISA metadata framework](https://isa-specs.readthedocs.io/en/latest/isamodel.html), so that it can be exported as ISA-JSON. When referring to Investigation, Study, and Assay within an ISA-JSON compliant experiment, we use the terms ISA Investigation, ISA Study, and ISA Assay to emphasize the additional information required.

<div class="alert alert-info">
Note that the ISA-JSON compliance feature must be enabled by the platform administrator. If you do not see the ISA-JSON compliance options in your Project, please contact your local instance administrator.
</div>


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


## Experiment Sample Templates

[Experiment Sample Templates](isajson-templates.html) act as blueprints to create Sample Types within ISA Studies and ISA Assays and ensure that 
the metadata collected conforms to community standards.

Experiment Sample Templates can be [provided by the platform administrator](isajson-templates.html#for-system-administrator) or created by Project members based on an existing template. Templates provided by the platform administrator are platform-wide (or instance-wide) and visible to every registered user. Project-specific Experiment Sample Templates created by Project members are subject to sharing permissions.

See [Experiment Sample Templates](isajson-templates.html) for more information.


## Samples in ISA-JSON compliant Experiments

In ISA-JSON compliant experiments, samples must be created within a Sample Type derived from an Experiment Sample Template, associated with one ISA Study or one ISA Assay.

The "level" of the Experiment Sample Template applied to generate a Sample Type within an ISA Study or ISA Assay determines the type of samples that will be created. Specifically, 
* ISA Study Source Template for Study Sources
* ISA Study Sample Template for Study Samples
* ISA material output Assay Template for material samples
* ISA data file Assay Template for digital data file samples

See [Working with Samples in ISA-JSON compliant Experiments](create-sample-isajson-compliant.html) for more information.

## Designing ISA-JSON compliant Experiments

See [Designing ISA-JSON compliant Experiments](designing-experiments-isajson-compliant.html) for a step-by-step description 
of how to set up ISA-JSON compliant Experiments.

## ISA-JSON export
[Export Experiments as ISA-JSON](exporting-experiments-as-isajson.html)

