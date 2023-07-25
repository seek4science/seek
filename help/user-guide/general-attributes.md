---
title: SEEK User Guide - Generic linking variables
layout: page
redirect_from: "/help/user-guide/generic-linking-variables.html"
---

# Generic linking variables in SEEK

## Title
You should make titles as descriptive as possible.

## Description
The description allows you to further expand important details.
Descriptions can be formatted using [markdown](https://www.markdownguide.org/basic-syntax/), either via markup or using the various options above the text input (e.g. bold, italics, hyperlinks...).

![Markdown ribbon UI](/images/user-guide/description_markdown_ribbon.png){:.screenshot}


## Projects
Assets can be assigned to projects in which they were created using the drop down menu.
![add project 1](/images/user-guide/add_project_1.png){:.screenshot}

You can remove any selected projects using the remove button.
![add project 2](/images/user-guide/add_project_2.png){:.screenshot}

## Investigation details

## Study
[Assay specific] You can link an assay to a particular study within your projects using the drop down menu.

## Biological Problem Addressed
[Assay specific - modelling analysis] You can select which biological problem is addressed with the modelling analysis using the drop down menu. You can also add you own using the new modelling analysis type button.

![Biological problem addressed 1](/images/user-guide/biological_problem_addressed_1.png){:.screenshot}

## Assay Type
[Assay specific - experimental assay]
You can select an assay type from the drop down menu, or where appropriate create a new assay type using the new assay type button.

![Assay Type 1](/images/user-guide/assay_type_1.png){:.screenshot}

## Technology Type
[Assay specific - experimental assay]
You can select a technology type from the drop down menu, or where appropriate create a new technology type using the new technology type button.

![Technology Type 1](/images/user-guide/technology_type_1.png){:.screenshot}

## Organisms
[Assay specific]
You can select an organism from the drop down menu.

![organism 1](/images/user-guide/organism_1.png){:.screenshot}

## Experimentalists


## Sharing

FAIRDOM-SEEK has fine grained sharing permissions. You can choose to set an item private (no access) or to share it with selected people, institutions, projects or programmes within SEEK, or to share it publicly. 

There are different levels of sharing permissions: 
* "View" allows to see only the title and description of an item;
* "Download" gives access to the content;
* "Edit" allows to change details of attributes of the item;
* "Manage" gives rights to change project assignments, sharing permissions, creators or to add a temporary sharing link. Only with manage rights an item can be deleted permanently.

![sharing permissions](/images/user-guide/sharing_permissions.png){:.screenshot}

An item's sharing permissions can be set 
* by managing the asset individually
* via the "Batch permission changes" button in your user profile.


## Publishing

An item is only considered *published* if its **Public** sharing permissions are set to:
- **View** if the item is not downloadable (Investigations, Studies, Assays...);
- **Download** if the item is downloadable (SOPs, Documents, Data Files...).

Non-public items can be published
* individually through the "Publish" button in the item's actions menu,
* by managing the item and changing its **Public** sharing permissions to a published status (see definition above),
* in bulk, via the "Batch permission changes" button in your user profile. The same sharing permission rules for considering an item as published apply.

"Publish your assets" button in your user profile allows you to publish Assets in batch.

![batch sharing publishing](/images/user-guide/bulk-permission-change/batch_sharing_publishing.png){:.screenshot}

When you attempt to publish an item in a project that has gatekeeper(s), you will be shown a notice about the gatekeeper being notified.

## Tags
Tags are key words that are relevant in some way to the asset and its properties. They are used so relevant assets can be found more easily by other users using key-word searches. To include a tag you just type it into the box. Suggestions of tags will appear in a drop down menu as you type. You are free to use any free text for tags.

![add tags 1](/images/user-guide/add_tags_1.png){:.screenshot}

## Attributions
An attribution in SEEK allows you, where appropriate, to select the asset from which your asset was derived from (stored within SEEK). As you type in the attribution, related assets will appear in a drop down menu.

![add tags 1](/images/user-guide/add_attribution_1.png){:.screenshot}

## Creators
Creators are others who have been involved in generating the asset, through for example planning, experimentation, or analysis. 
They may not necessarily be the same person that registered the item - the Contributor.


You can add multiple creators, either one by one. Start to type the name and matching entries will be displayed. Hit ENTER, comma or click to add the person

![add creator](/images/user-guide/add-creator.png){:.screenshot}


You can also include non-SEEK creators.

You can also add non-SEEK creators using free text.

![add non-SEEK creator](/images/user-guide/add-non-seek-creator.png){:.screenshot}

Creators can be removed easily where necessary.


## SOPs
[Assay specific]
SOPs are standard operating procedures which describe the protocol required to reproduce the assay. They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant SOPs can be linked directly to the assay via the dropdown menu.

## Data Files
[Assay specific]
Data files can be any file containing data relevant to the assay (raw data, processed data, calibration information etc). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant data files can be linked directly to the assay via the dropdown menu.

## Placeholders
[Assay specific]
A Placeholder indicates data that will be consumed, used or produced when a Project is enacted. Placeholders are used when the structure of a Project is defined, but, because the Project has not yet been fully enacted, the data may not yet be known. When the data is known, the Data File may be associated with the Placeholder it satisfies. Placeholders may be used anywhere a DataFile can be.

## File Templates
A File Template describes conforming DataFiles. It may be annotated with information about the format and type of data in the DataFiles. Annotations are *not* about the File Template itself. For example, a File Template that is a Word document may describe conformant PNG images.

## Publications
If your asset is directly related to a publication you can link the two together in SEEK. You can select publications within your project form the drop-down menu. If the publication is in another project you need to check the box that says associate publications from other projects.

![add publication 1](/images/user-guide/add_publication_1.png){:.screenshot}

When a publication is added a preview will be shown in the bottom right hand corner of SEEK. It can be removed easily if needed.

![add publication 2](/images/user-guide/add_publication_2.png){:.screenshot}

## Experimental assays and Modelling analysis
It is best that assets are contextualised using the ISA graph (more later). This means that assets where possible should be linked to an assay or an experimental analysis. This can be done by selecting an appropriate assay or experimental analysis from the drop down menu.

![add assay 1](/images/user-guide/add_assay_1.png){:.screenshot}

An assay preview will appear on the right hand side of SEEK once selected. The linking can be removed from the asset easily.

![add assay 2](/images/user-guide/add_assay_2.png){:.screenshot}

## Experimental assays and modelling analysis

## Events
If the asset was generated as part of an event that is registered in SEEK, you can link to the asset to the event using the drop down menu.

![add event 1](/images/user-guide/add_event_1.png){:.screenshot}

A preview of the event will appear on the right hand side of SEEK once selected. The link can be removed from the asset easily.

![add event 2](/images/user-guide/add_event_2.png){:.screenshot}
