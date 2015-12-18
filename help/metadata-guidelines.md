---
title: Metadata Guidelines
layout: page
redirect_from: "/metadata-guidelines.html"
---

# Minimum Metadata Guidelines for SEEK

**This guide refers to SEEK, but is also relevant for [FAIRDOMHUB](https://www.fairdomhub.org/), which is an instance of SEEK.**

The more metadata you provide for your assets in the SEEK, the easier it is to find them and to compare them with other assets. If you provide assets with very little metadata, these will also be displayed (in accordance with access control policies set by you), but they may be hard to interpret for other people.

In addition to SEEK data sharing guidelines, some types of data have minimum metadata requirements for publication, for example, microarray data must be MIAME compliant. Following the guidelines for SEEK metadata should ensure that when you come to publish, you have already met these requirements.   
These guidelines outline what we recommend for SEEK.

## General SEEK Metadata

**Name** (of the data uploader). This is the person responsible for the data and responsible for setting sharing and dissemination policies. If more than one person was involved in the experiment, you can credit these people separately   
**SEEK ID** – (Of the above person). This helps us identify each person within SEEK.   
**Project** – The name of the project that the asset relates to. If you are uploading directly to SEEK and you are in more than one project in SEEK, it is important to specify. Typically, an asset will belong to only one project.  
**Upload Date (yymmdd)**. This is the date of publication to SEEK rather than the date of the experiment. Depending on the system your project uses, we will try to automatically detect when changes are made to a file. Each upload will automatically receive its own timestamp when uploaded directly into SEEK  
**Experiment Date (yymmdd)**. This is the date the experiment was performed  
**Title** – a unique name for your asset file. If you upload manually, you will receive an error message if the file title is not unique within your project. If your asset is uploaded via a JERM Harvester without a title, you will receive an email notification.  
**Version Number** – If your file replaces an existing file, the version number will help us pick this up. Keep it simple, versions should go up by integers.  
**Names of other people involved** – many experiments involve multiple steps and multiple people. This metadata field allows you to give credit and attribution to all those involved

## ISA Framework
For more information on how the ISA Framework is implemented in SEEK please visit [A Quick Guide to Using the ISA Structure](isa-guide.html), for more information about ISAtab itself please visit http://isatab.sourceforge.net/format.html 

### Investigation

**Title** – described above. All assets should have a title  
**Description** – free text describing the purpose of the investigation  
**Project** – as described above. All assets should be associated with a project

### Study

**Title** – as described above. All assets should have a title  
**Description** – free text describing the purpose of the study  
**Person Responsible** – the creator of the study description  
**Experimentalists** – other scientists involved in any of the work in the study. If they are registered SEEK users, please give their SEEK ID, so we can link to their profiles in SEEK. If they are not registered in SEEK, their names will still be displayed, but not linked. People's involvement can also be inferred from anyone named in included assays.  
**Project** – as described above. All assets should be associated with a project  
**Investigation title** – The name of the investigation the study belongs to.

### Assay

**Assay Title** – The name of the assay that the asset links to.   
**Assay type** – The controlled vocabulary term describing the assay classification comes from the JERM ontology. Users can also describe their own.     
**Technology type** – The controlled vocabulary term describing the technology used in the assay  
Users can also describe their own.   
**Study title** – The name of the study the assay belongs to. An assay can belong to more than one study  
**Organism** The name of the organism being studied with this asset. If uploading through SEEK, organism names are provided as a drop-down list. Users can also describe their own.   
**Strain** The name of the particular strain being studied  
**WT/Mutant** – Specifies whether this strain is wild-type or mutant  
**Genotype** – a brief text description of the genotype  
**Phenotype** – a brief text description of the phenotype  
**Culture Growth** – This describes how the culture was grown for this assay. You can choose values from a drop-down list when adding new assays directly to SEEK  
**Data File Titles** – the title of one or many data files produced during this assay  
**SOP Titles** – the title of one or many SOPs used to execute this assay

## SEEK Assets (data, models, SOPs, maps etc)

### Data

**Title** – as described above  
**Description** – free text to describe what the data is showing  
**File Format** – how the data is stored, for example excel spreadsheet  
**Factors Studied** – what experimental parameters did you alter in order to study the effects in the organism (e.g. changing the pH from 5 to 7)  
**Measured Item** – what was measured in this data, e.g. concentration of glucose. Measured items should be named using controlled vocabulary terms wherever possible, for example, glucose has chEBI name glucose and chEBI ID CHEBI:17234  
**Units** – how the measurements were taken, e.g. concentration in mmol, or mass in grams.

### Models

**Filename/archive name** – the title of the asset  
**Description** – free text to describe what the model is showing  
**Model Type** – what kind of mathematical equations does your model contain e.g. ODE, algebraic  
**Model Format** – e.g. SBML, CellML. If uploading directly through SEEK, you will be able to chose from a drop-down list  
**Model Execution Environment and URL** – how do you run a simulation on your model? This field should provide a link to a tool or resource which would allow you to run your model  
**Linking Models to Data** – this section allows you to specify how and where data files were used to a) construct your model b) validate your model, or c) record simulation results from your model. If you are uploading directly through SEEK, you can find the relevant files by searching a drop-down list.

### SOPs

**Title** – as described above. All assets should have a title  
**Description** – free text to describe what the SOP is used for  
**Experimental conditions** – what was standardised and fixed in this experiment (e.g. concentration of nutrients, pH, temperature). If you are uploading directly through SEEK, you can chose from a drop-down list  
**Units** – how the measurements were taken e.g. concentration in mmol or mass in grams.

### Publications

**PubmedID or DOI** – the SEEK can extract publication abstracts from PubMed, when supplied with a PubmedID. When the paper abstract is retrieved, you can verify which people from a drop-down list are authors from within the consortium, so that we can link to their profile.  
Publications can be linked to other assets (data, models, SOPs) to allow you to use the SEEK as a supplementary data store.

**Attribution** – Some assets are based on others, for example, a model may use data from an experimental assay, or a SOP may be a modified version of another. The attribution section allows you to specify when this is the case 

## Contributing 
SEEK documentation is a community driven activity. If you have any modifications you want to make to the guidelines please send requests, or feedback to <community@fair-dom.org>.