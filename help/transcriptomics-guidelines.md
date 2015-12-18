---
title: Transcriptomics Guidelines
layout: page
redirect_from: "/transcriptomics-guidelines.html"
---

**This guide refers to SEEK, but is also relevant for [FAIRDOMHUB](https://www.fairdomhub.org/), which is an instance of SEEK.**

# Transcriptomics: Guidelines for SEEK Templates

The MIAME standard and the associated MAGE-ML format are well established in the transcriptomics community and adherence to MAGE-ML is becoming increasingly important for publishing data.

MAGE-TAB is a tab delimited representation of MAGE-ML. It allows users to construct MIAME compliant excel spreadsheets. The ISA-TAB specification also allows an export to MAGE-TAB format.

For SEEK, we recommend you use MAGE-TAB templates for transcriptomics data. We have a JERM mapping for MAGE-TAB, so as long as you do not change the headers and titles of worksheets, we can extract your data in this format.

There are several parts to a MAGE-TAB file. These parts can be represented as separate files, or separate worksheets in excel. MAGE-TAB consists of:

**IDF – Investigation Description Format**  
This worksheet is an overview of the experiment, factors studied, protocols, publication information and contact details.

**SDRF – Sample and Data Relationship Format**  
This worksheet details the links between sample and data, it can include information about the source (e.g. organism rat), the sample (e.g. rat liver), extracts (e.g. total RNA), labelled extract (e.g. synthetic DNA), hybridisations (e.g. a reference on the Array as defined by the ADF), raw data (e.g. a reference to a raw data file), normalisation (e.g. a reference to normalised data file), derived array data files (e.g. a reference to a derived data file, or file matrix)

**Raw Data and Processed Data**  
These worksheets hold the actual and derived data values

**ADF – Array Design Format (optional)**  
This worksheet provides the array-level annotation for the experiment, relating the row-level identifiers in the data files to biological sequence annotation.

There are a detailed [set of help pages and examples provided by the MGED community][1]

There are also tools to help you construct MAGE-TAB templates on the web. For example, there is the [ArrayExpress submission help system][2] and there is the [ISA curator tool from the ISA-TAB group][3]

## Notes and additions for SEEK

### IDF

Many of the personal details in the IDF sheet can be automatically extracted from your SEEK profile. If you add your SEEK ID as an additional field (called SEEK ID), we can extract all your personal details from your profile so there is no need to complete these personal details fields.   
Similarly, you can refer to protocols (SOPs in SEEK) by their SEEK ID, and we can automatically extract their name and brief description.  
This worksheet also contains fields to link to publications. In many cases, data could be shared in SEEK before publication. If so, please leave these fields blank, but do not remove them.

### SDRF

This file links the sample and source information to the data files and their locations.  
The "protocol" columns will normally be followed by "factor value" columns. Again, we can extract these from the experimental conditions and factors studies sections of SEEK where you are referring to a SOP already submitted.

### Raw Data and Processed Data

##### Raw Data

We do not generally expect you to share raw data within SEEK by default, but links to this upon request are essential. The MAGE-TAB specification supports many different types of raw data format. For a complete list, please see [here][4]

##### Processed Data

If your processed data maps to the identifier in your array design, you can create a single results file with column 1 being those identifiers with the heading "Reporter Identifier" followed by the quantitation columns with the quantitation types as the headings and the column of data values. Additionally, you may want to add columns for a name and/or description of identifier, but this is optional

### ADF

This worksheet is necessary when submitting your array data to a public repository, but it is optional for SEEK. It is a physical description of the array. Many commercial and academic array designs have already been submitted to ArrayExpress, so you could simply reference your design from ArrayExpress. Affymetrix, Agilent, Illumina, Nimblegen and Sanger array designs have already been submitted and can be explored [here][5]

## Contributing 
SEEK documentation is a community driven activity. If you have any modifications you want to make to the guidelines please send requests, or feedback to <community@fair-dom.org>.

[1]: http://tab2mage.sourceforge.net/docs/magetab_docs.html
[2]: http://www.ebi.ac.uk/cgi-bin/microarray/magetab.cgi
[3]: https://github.com/ISA-tools/ISAcreator
[4]: http://tab2mage.sourceforge.net/docs/datafiles.html
[5]: http://www.ebi.ac.uk/microarray-as/aer/entry
  