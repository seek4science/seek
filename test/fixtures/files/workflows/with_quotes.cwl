#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
requirements:
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}
  MultipleInputFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

label: Kallisto RNAseq Workflow
doc: | 
  Workflow Kallisto RNAseq
    - Workflow Illumina Quality: https://workflowhub.eu/workflows/336?version=1	
    - kallisto (pseudoalignment on transcripts)

  **All tool CWL files and other workflows can be found here:**<br>
    Tools: https://git.wur.nl/unlock/cwl/-/tree/master/cwl<br>
    Workflows: https://git.wur.nl/unlock/cwl/-/tree/master/cwl/workflows<br>

  The dependencies are either accessible from https://unlock-icat.irods.surfsara.nl (anonymous,anonymous)<br>
  and/or<br>
  By using the conda / pip environments as shown in https://git.wur.nl/unlock/docker/-/blob/master/kubernetes/scripts/setup.sh<br>

outputs:
  illumina_quality_stats:
    label: Filtered statistics
    doc: Statistics on quality and preprocessing of the reads
    type: Directory
    outputSource: workflow_quality/reports_folder
  kallisto_output:
    type: Directory
    label: kallisto output
    doc: kallisto results folder. Contains transcript abundances, run info and summary.
    outputSource: kallisto_files_to_folder/results

inputs:
  identifier:
    type: string
    doc: Identifier for this dataset used in this workflow
    label: identifier used
  threads:
    type: int?
    doc: number of threads to use for computational processes
    label: number of threads
    default: 2
  memory:
    type: int?
    doc: Maximum memory usage in megabytes
    label: Maximum memory in MB
    default: 40000
  filter_rrna:
    type: boolean
    default: true
  forward_reads:
    type: string[]
    doc: forward sequence file locally
    label: forward reads
  reverse_reads:
    type: string[]
    doc: reverse sequence file locally
    label: reverse reads
  kallisto_index:
    type: Directory?
    label: folder where the kallisto indices are
  contamination_references:
    type: string[]?
    doc: bbmap reference fasta file for contamination filtering
    label: contamination reference file

  destination:
    type: string?
    label: Output Destination
    doc: Optional Output destination used for cwl-prov reporting.

steps:
  #########################################
  # Workflow for quality and filtering of raw reads
  workflow_quality:
    label: Quality and filtering workflow
    doc: Quality assessment of illumina reads with rRNA filtering option
    run: workflow_illumina_quality.cwl
    in:
      forward_reads: forward_reads
      reverse_reads: reverse_reads
      filter_references: contamination_references
      memory: memory
      threads: threads
      identifier: identifier
      filter_rrna: filter_rrna
      step:
        default: 1
    out: [QC_reverse_reads, QC_forward_reads, reports_folder]
  #########################################
  # kallisto transcript abundances
  kallisto:
    label: kallisto
    doc: Calculates transcript abundances
    in:
      prefix: identifier
      forward_reads: workflow_quality/QC_forward_reads
      reverse_reads: workflow_quality/QC_reverse_reads
      indexfolder: kallisto_index
      threads: threads
    run: ../RNAseq/kallisto/kallisto_quant.cwl
    out:
      [abundance.h5, abundance.tsv, run_info, summary]

#############################################
#### Move to folder if not part of a workflow
  kallisto_files_to_folder:
    label: kallisto output
    doc: Preparation of kallisto output files to a specific output folder
    in:
      identifier: identifier
      files:
        source: [kallisto/abundance.h5, kallisto/abundance.tsv, kallisto/run_info, kallisto/summary]
        linkMerge: merge_flattened
        pickValue: all_non_null
      destination:
        default: $(inputs.identifier)"_kallisto"
    run: ../expressions/files_to_folder.cwl
    out:
      [results]
#############################################

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0001-8172-8981
    s:email: mailto:jasper.koehorst@wur.nl
    s:name: Jasper Koehorst
  - class: s:Person
    s:identifier: https://orcid.org/0000-0001-9524-5964
    s:email: mailto:bart.nijsse@wur.nl
    s:name: Bart Nijsse

s:citation: https://m-unlock.nl
s:codeRepository: https://gitlab.com/m-unlock/cwl
s:dateCreated: "2022-05-00"
s:license: https://spdx.org/licenses/Apache-2.0 
s:copyrightHolder: "UNLOCK - Unlocking Microbial Potential"


$namespaces:
  s: https://schema.org/
