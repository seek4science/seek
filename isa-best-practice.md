---
title: ISA Best Practice
layout: page
---

# ISA Best Practice Guide

The ISA Infrastructure (Investigation, Study, Assay) is a general purpose framework for describing how experiments relate to one another. It describes both metadata (samples, characteristics, technologies, etc) and data (transcriptomics, proteomics etc), but the data itself is stored separately, and can therefore be as public or private as required. The ISA descriptions are visible to the rest of the SysMO consortium.  
The original purpose of the ISA infrastructure was to provide a common framework for relating multiple omics data and to provide a single mechanism for submission to omics data silos (such as ArrayExpress for Microarray data, or PRIDE, for proteomics data). SysMO data often involves omics data and generally relies on the integration of multiple data types, so the ISA infrastructure will provide a mechanism for SysMO data export as well as providing a common framework for navigation.   
For more information on the ISA community work, please see:  
[http://isatab.sourceforge.net/index.html](http://isatab.sourceforge.net/index.html)


## Examples

There are many ways to describe your projects and the relationships between the different work-packages and research topics. The following guidelines provide a general description of the ISA Infrastructure and examples of how this may fit with your SysMO project. We use examples from the [Bioinvestigation Index (BII)](http://www.ebi.ac.uk/bioinvindex/), which is a public database of ISA compliant data. We also use examples already available in SysMO

* **Investigation:** a high level description of the area and the main aims of a project
    * In SysMO, this may be the overall aims as stated on the sysmo.net website.   
If your project has several subprojects that do not share any data, you should define an investigation for each.
    * **BII Example:** Growth control of the eukaryote cell: a systems biology study in yeast
    * **SysMO Example** Analysis of Central Carbon Metabolism of Sulfolobus solfataricus under varying temperatures
* **Study:** a particular biological hypothesis or analysis
    * In SysMO, these studies may contain only experimental assays, only modelling analyses, only informatics analyses,   
or a mixture of all
    * **BII Example:** Study of the impact of changes in flux on the transcriptome, proteome, endometabolome and exometabolome   
of the yeast Saccharomyces cerevisiae under different nutrient limitations
    * **SysMO Example:** Comparison of S. solfataricus grown at 70 and 80 degrees
* **Assay:** specific, individual experiments required to be undertaken together in order to address the study hypotheses.
    * In SysMO, this may be one single microarray experiment, or one flux balance analysis, for example
    * **BII Example:**
        * Transcriptional profiling
        * DNA Microarray
    * **SysMO Example:**
        * Comparison of transcriptome 70 and 80c (Cdna microarray)
        * Comparison of proteome at 70 and 80c (Protein expression profiling)
        * Intracellular metabolomics of s. solfataricus at 70 and 80c (Metabolomics)

## Required Fields in the SysMO ISA

A short guide to creating a new ISA file

### Investigation

**Title** – The name of the investigation. All assets should have a title  
**Description** – free text describing the purpose of the investigation  
**Project** – The project that the investigation belongs to. All assets should be associated with a project

### Study

**Title** – The name of the Study. All assets should have a title  
**Description** – free text describing the purpose of the study  
**Person Responsible** – the creator of the study description  
**Experimentalists** – other scientists involved in any of the work in the study. If they are in SysMO, please give their SEEK ID, so we can link to their profiles in SEEK. If they are not in SEEK, their names will still be displayed, but not linked. People's involvement can also be inferred from anyone named in included assays.  
**Project** – The project that the study belongs to. All assets should be associated with a project  
**Investigation title** – The name of the investigation the study belongs to.

### Assay

**Assay Title** – The name of the assay that the asset links to.   
**Assay type** – The controlled vocabulary term describing the assay classification  
If you cannot find a suitable Assay Type term, please contact us or your PAL to update the vocabulary   
**Technology type** – The controlled vocabulary term describing the technology used in the assay  
If you cannot find a suitable Technology Type term, please contact us or your PAL to update the vocabulary   
**Study title** – The name of the study the assay belongs to. An assay can belong to more than one study  
**Organism** The name of the organism being studied with this asset. If uploading through SEEK, organism names are provided as a drop-down list  
**Strain** The name of the particular strain being studied  
**WT/Mutant** – Specifies whether this strain is wild-type or mutant  
**Genotype** – a brief text description of the genotype  
**Phenotype** – a brief text description of the phenotype  
**Culture Growth** – This describes how the culture was grown for this assay. You can choose values from a drop-down list when adding new assays directly to SEEK  
**Data File Titles** – the title of one or many data files produced during this assay  
**SOP Titles** – the title of one or many SOPs used to execute this assay  