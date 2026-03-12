#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: Workflow
requirements:
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}
  MultipleInputFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}

label: Microbial (meta-) genome annotation
doc: Workflow for microbial genome annotation.

outputs:
  bakta_folder:
    type: Directory
    outputSource: bakta_to_folder/results
  compressed_other_files:
    type: File[]
    outputSource: compressed_other/outfile
    linkMerge: merge_flattened
    pickValue: all_non_null
  #when compression is turned off
  uncompressed_other_files:
    type: File[]?
    outputSource: uncompressed_other/outfiles
  sapp_hdt_file:
    type: File?
    outputSource: workflow_sapp_conversion/hdt_file

inputs:
  threads:
    type: int?
    default: 4
    doc: Number of threads to use for computational processes. Default 4
    label: Number of threads
  genome_fasta:
    type: File
    label: Genome fasta file
    doc: Genome fasta file used for annotation (required)
  codon_table:
    type: int
    default: 11
    doc: Codon table 11/4. Default = 11
    label: Codon table
  bakta_db:
    type: Directory?
    label: Bakta DB
    doc: | 
      Bakta database directory (default bakta-db_v5.1-light built in the container) (optional)
  metagenome:
    type: boolean
    label: metagenome
    doc: Run in metagenome mode. Affects only protein prediction. Default false
    default: false
  skip_bakta_plot:
    type: boolean
    label: Skip plot
    doc: Skip Bakta plotting
    default: false
  skip_bakta_crispr:
    type: boolean
    label: Skip bakta CRISPR array prediction using PILER-CR
    doc: Skip CRISPR prediction
    default: false
  interproscan_directory:
    type: Directory?
    label: InterProScan 5 directory
    doc: Directory of the (full) InterProScan 5 program. When not given InterProscan will not run. (optional)
  
  interproscan_applications:
    type: string
    default: 'Pfam'
      # SFLD,SMART,AntiFam,NCBIfam not available yet
    label: Interproscan applications
    doc: |
          Comma separated list of analyses:
          FunFam,SFLD,PANTHER,Gene3D,Hamap,PRINTS,ProSiteProfiles,Coils,SUPERFAMILY,SMART,CDD,PIRSR,ProSitePatterns,AntiFam,Pfam,MobiDBLite,PIRSF,NCBIfam
          default Pfam,SFLD,SMART,AntiFam,NCBIfam

  eggnog_dbs:
    type:
      - 'null'
      - type: record
        name: eggnog_dbs
        fields:
          data_dir:
            type: Directory?
            doc: Directory containing all data files for the eggNOG database.
          db:
            type: File?
            doc: eggNOG database file
          diamond_db:
            type: File?
            doc: eggNOG database file for diamond blast search

  run_kofamscan:
    type: boolean
    label: Run kofamscan
    doc: Run with KEGG KO KoFamKOALA annotation. Default false
    default: false
  kofamscan_limit_sapp:
    type: int?
    label: SAPP kofamscan filter
    doc: Limit max number of entries of kofamscan hits per locus in SAPP. Default 5
    default: 5
  run_eggnog:
    type: boolean
    label: Run eggNOG-mapper
    doc: Run with eggNOG-mapper annotation. Requires eggnog database files. Default false
    default: false
  run_interproscan:
    type: boolean
    label: Run InterProScan
    doc: Run with eggNOG-mapper annotation. Requires InterProScan v5 program files. Default false
    default: false

  compress_output:
    type: boolean
    doc: Compress output files. Default false
    default: false
  sapp_conversion:
    type: boolean
    doc: Run SAPP (Semantic Annotation Platform with Provenance) on the annotations. Default true
    default: true
  destination:
    type: string?
    label: Output Destination (prov only)
    doc: Not used in this workflow. Output destination used in cwl-prov reporting only.

steps:
  bakta:
    label: "Bakta"
    doc: "Bacterial genome annotation tool"
    when: $(inputs.bakta_db !== null)
    run: ../tools/bakta/bakta.cwl
    in:
      translation_table: codon_table
      fasta_file: genome_fasta
      db: bakta_db
      skip_crispr: skip_bakta_crispr
      meta: metagenome
      keep_contig_headers:
        default: true
      skip_plot: skip_bakta_plot
      threads: threads
    out: [hypo_sequences_cds,hypo_annotation_tsv,annotation_tsv,summary_txt,annotation_json,annotation_gff3,annotation_gbff,annotation_embl,sequences_fna,sequences_ffn,sequences_cds,plot_png,plot_svg]
############################
  kofamscan:
    label: "KofamScan"
    when: $(inputs.run_kofamscan && inputs.input_fasta.size > 1024)
    run: ../tools/kofamscan/kofamscan.cwl
    in:
      run_kofamscan: run_kofamscan
      input_fasta: bakta/sequences_cds
      threads: threads
    out: [output]
############################
  interproscan:
    label: "InterProScan 5"
    when: $(inputs.run_interproscan && inputs.interproscan_directory !== null && inputs.protein_fasta.size > 1024)
    run: ../tools/interproscan/interproscan_v5.cwl
    in:
      run_interproscan: run_interproscan
      interproscan_directory: interproscan_directory
      protein_fasta: bakta/sequences_cds
      applications: interproscan_applications
      threads: threads
    out: [tsv_annotations, json_annotations]
############################
  eggnogmapper:
    label: "eggNOG-mapper"
    when: $(inputs.run_eggnog && inputs.eggnog !== null && inputs.input_fasta.size > 1024)
    run: ../tools/eggnog/eggnog-mapper.cwl
    in:
      run_eggnog: run_eggnog
      input_fasta: bakta/sequences_cds
      eggnog_dbs: eggnog_dbs
      cpu: threads
    out: [output_annotations, output_orthologs]
############################
  compress_bakta:
    label: Compress Bakta
    run: ../tools/bash/pigz.cwl
    when: $(inputs.compress_output)
    scatter: [inputfile]
    scatterMethod: dotproduct
    in:
      compress_output: compress_output

      threads: threads
      inputfile:
        source: [bakta/hypo_sequences_cds, bakta/hypo_annotation_tsv, bakta/annotation_tsv, bakta/summary_txt, bakta/annotation_json, bakta/annotation_gff3, bakta/annotation_gbff, bakta/annotation_embl, bakta/sequences_fna, bakta/sequences_ffn, bakta/sequences_cds, bakta/plot_svg]
        linkMerge: merge_flattened
        pickValue: all_non_null
    out: [outfile]

  compressed_other:
    label: Compressed other
    doc: Compress files when compression is true
    when: $(inputs.compress_output)
    run: ../tools/bash/pigz.cwl
    scatter: [inputfile]
    scatterMethod: dotproduct
    in:
      compress_output: compress_output

      threads: threads
      inputfile:
        source: [kofamscan/output, interproscan/json_annotations, interproscan/tsv_annotations, eggnogmapper/output_annotations, eggnogmapper/output_orthologs]
        linkMerge: merge_flattened
        pickValue: all_non_null
    out: [outfile]

  uncompressed_other:
    label: Uncompressed other
    doc: Gather files when compression is false
    when: $(inputs.compress_output == false)
    run:
      class: ExpressionTool
      requirements:
        InlineJavascriptRequirement: {}
      inputs:
        files: File[]
      outputs:
        outfiles: File[]
      expression: |
                    ${return {'outfiles': inputs.files} }
    in:
      compress_output: compress_output
      files:
        source: [kofamscan/output, interproscan/json_annotations, interproscan/tsv_annotations, eggnogmapper/output_annotations, eggnogmapper/output_orthologs]
        linkMerge: merge_flattened
        pickValue: all_non_null
    out:
      [outfiles]

############################
  workflow_sapp_conversion:
    run: ../workflows/workflow_sapp_conversion.cwl
    when: $(inputs.sapp_conversion && inputs.embl_file.size > 1024)
    in:
      sapp_conversion: sapp_conversion
#      genome_fasta: genome_fasta
      identifier:
       valueFrom: $(inputs.embl_file.nameroot)
      embl_file: bakta/annotation_embl
      interproscan_output: interproscan/json_annotations
      kofamscan_output: kofamscan/output
      kofamscan_limit: kofamscan_limit_sapp
      threads: threads
    out: [hdt_file]

############################
  bakta_to_folder:
    label: Bakta to folder
    doc: Move all Bakta files to a folder
    run: ../tools/expressions/files_to_folder.cwl
    when: $(inputs.bakta_db !== null)
    in:
      files: 
        source: [compress_bakta/outfile, bakta/plot_png]
        linkMerge: merge_flattened
        pickValue: all_non_null

      destination:
        source: genome_fasta
        valueFrom: $("Bakta_"+self.nameroot)
    out:
      [results]

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
s:dateCreated: "2020-00-00"
s:dateModified: "2024-08-05"
s:license: https://spdx.org/licenses/Apache-2.0 
s:copyrightHolder: "UNLOCK - Unlocking Microbial Potential"


$namespaces:
  s: https://schema.org/