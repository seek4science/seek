---
title: SEEK User Guide - Create Sample in ISA-JSON compliant Experiments
layout: page
---

# Viewing samples in ISA-JSON compliant Experiments
Samples in ISA-JSON compliant Experiments can be visualised in the "design" tab (Study or Assay design). Samples are grouped in tables: Study Sources table, Study Samples table, Assay Samples table, Experiment overview.

## Sources table and Samples table
Sources table and Samples table are interactive tables (dynamic tables) that allow samples creation and editing. 
* Studies contain both Sources table and Samples table.
* Assays contains only Samples table.

## samples
In Experiment View, you can also view Study Sources, Study Samples, and Assay Samples in a searchable table by selecting "samples (n)" from the tree view on the left sidebar. Samples cannot be created or edited via this view.

![dynamic table isa study source](/images/user-guide/isajson-compliance/dynamictable_isastudy_source.png){:.screenshot}

## Experiment overview
Experiment overview table shows an overview of all Sources and Samples in a searchable table. Samples cannot be created or edited via this view.
* In ISA Study, Experiment overview shows Study Sources and Study Samples.
* In ISA Assay, Experiment overview shows Study Samples and Assay samples, up until that experimental step.

# Create Study Sources
From Study design tab, Sources can be created in three ways.

## Via the Add row button. 
1. Select the Add row button at the bottom of the page. One row corresponds to one Source.
2. Make sure to fill in all the mandatory columns and then select Save.
* Note that the light blue cells will define the name of each Source.
3. Click on Save. For each row that gets saved, a single Study Source is created.

## Via the Paste From Clipboard button
1. Use one of the following buttons to export the table and save it locally: "Export to CSV", "Copy to Clipboard" or "Batch download to Excel".
2. Fill in the table offline and copy the content. Ensure to select and copy all columns except for "id" and "uuid".
3. Use the "Paste From Clipboard" button to fill in the table.
4. Select Save. For each row that gets saved, a single Source is created.

## Via upload of the downloaded dynamic table
1. Click on "Batch download to Excel".
2. Open the downloaded excel file, fill in the table offline and save it locally.
3. Navigate to the same Sources table from the Study design tab, click on "Choose File" button at the bottom of the page, select the saved excel file and click "Upload".
4. Verify and confirm the upload via the pop-up window, then click "Save".

![create study sources](/images/user-guide/isajson-compliance/create_samples_isastudy_source_4.png){:.screenshot}

# Create Study Samples 
In the Study design tab, Samples can be created in three ways, similar to Sources (see above). The only difference is the mandatory column "Input" in the Samples table, which must be filled with valid and existing Sources from the same Study.

## Via the Add row button. 
Select the input Source(s) for the Sample your are creating in the "Input" column.

## Via the Paste From Clipboard button
Ensure to select and copy all columns except for "Input", "id" and "uuid". "Input" cannot be pasted from clipboard, it must be added manually.

![create study samples 5](/images/user-guide/isajson-compliance/create_samples_isastudy_samples_5.png){:.screenshot}

## Via upload of the downloaded dynamic table
Values for the mandatory column "Input" in the Samples table can be added in batch via spreadsheet upload.

Open the downloaded excel file and fill in the "Input" column by providing the *Source id* and the *Source title* in the following format. id: numeric id assigned by the platform to each Source; title: Source Name given by the user to each Source.

One input value:

[{"id"=>343, "type"=>"Sample", "title"=>"yeast_wgs_02"}].

Two input values:

[{"id"=>343, "type"=>"Sample", "title"=>"yeast_wgs_02"}, {"id"=>342, "type"=>"Sample", "title"=>"yeast_wgs_01"}]

![create study samples 6](/images/user-guide/isajson-compliance/create_samples_isastudy_samples_6.png){:.screenshot}

Navigate to the same Sources table from the Study design tab, click on "Choose File" button at the bottom of the page, select the saved excel file and click "Upload". Verify and confirm the upload via the pop-up window, then click "Save".

# Create Assay Samples 
In the Assay design tab, Samples can be created in three ways, similar to Study Samples (see above). The only difference is the mandatory column "Input" in the Assay Samples table.
* For first Assay, it must be filled with valid and existing Study Samples from the same Study.
* For subsequent Assays, it must be filled with valid and existing Assay Samples from the previous Assay in the same Assay Stream.