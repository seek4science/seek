---
title: SEEK User Guide
layout: page
---

# SEEK user documentation

## Content

- [Contributing to SEEK Docs](#contributing)
- [Registering in SEEK](#registering-in-seek)
- [Logging into SEEK](#logging-into-seek)
- [Editing your profile](#editing-your-profile)
- [Managing your account](#managing-your-account)
- [Adding assets (data, models, SOPs, publications) to SEEK](#adding-assets-(data,-models,-SOPs,-publications)-to-seek)
- [Generating the ISA structure](#generating-the-isa-structure)
     - [Creating an Investigation](#creating-an-investigation)
     - [Creating a study](#creating-a-study)
     - [Creating an experimental assay](#creating-an-experimental-assay)
     - [Creating a modelling analysis](#creating-a-modelling-analysis)
- [Generic linking variables in SEEK](#generic-linking-variables-in-seek)
     - [Title](#title)
     - [Description](#description)
     - [Projects](#projects)
     - [Investigation details](#investigation-details)
     - [Study](#study)
     - [Biological Problem Addressed](#biological-problem-addressed)
     - [Assay Type](#assay-type)
     - [Technology Type](#technology-type)
     - [Organisms](#organisms)
     - [Experimentalists](#experimentalists)
     - [Sharing](#sharing)
     - [Tags](#tags)
     - [Attributions](#attributions)
     - [Contributors](#contributors)
     - [SOPs](#sops)
     - [Data Files](#data-files)
     - [Publications](#publications)
     - [Experimental assays and Modelling analysis](#experimental-assays-and-Modelling-analysis)
     - [Events](#events)
- [Making an investigation citable](#making-an-investigation-citable)
     - [Making public](#making-public)
     - [Snapshotting](#snapshotting)
     - [Creating a Research Object](#creating-a-research-object)
     - [Assigning a DOI](#assigning-a-doi)
- [Specialist user roles](#specialist-user-roles)
     - [Asset housekeeper](#asset-housekeeper)
     - [Asset gatekeeper](#asset-gatekeeper)
     - [Project administrator](#project-administrator)
                  - [Add and remove people from a project](#add-and-remove-people-from-a-project)
                  - [Create Organisms](#create-organisms)
                  - [Create Profiles](#create-profiles)
                  - [Create Institutions](#create-institutions)
                  - [Assign people to project roles](#assign-people-to-project-roles)
                  - [Flag when a person leaves a project](#flag-when-a-person-leaves-a-project)
                 
## Contributing 
If you want to contribute or make modifications to the SEEK documentation please contact <community@fair-dom.org> for more details.

##Registering in SEEK
In order to register yourself in SEEK, you need to click Register button in the top right hand corner of SEEK.

![Registration 1](/images/user-guide/register_1.png)

It will take you to a screen where you need provide

* A Login name (can be your real name, or another appropriate name
* An email address
* A password for your account
When complete click the Register button in the bottom left hand corner.

![Registration 2](/images/user-guide/register_2.png)

You will then be taken to a screen where you will enter further information. We require the following information:

* First Name
* Last Name
* ORCID ID - if you do not have an ORCID you will need to register for one here http://orcid.org/
* Your email address, which should be automatically populated from the previous screen.

If your project is already in SEEK please select it from the dropdown menu.
If your institute is already in SEEK please select it from the dropdown menu.  

![Registration 3](/images/user-guide/register_3.png)

After you have registered the rest of your information you will need to activate your account. You will receive an email in the email account you have provided.

![Registration 4](/images/user-guide/register_4.png)


## Logging into SEEK

To log in you need to click the login button in the top right hand corner of SEEK. 

![Login 1](/images/user-guide/login_1.png)

This will take you to a page where you need to enter your username, and password.

![Login 2](/images/user-guide/login_2.png)

## Editing your profile
To edit your profile, you must be logged in. When logged in you can click your name in the top right hand corner of SEEK.

![edit profile 1](/images/user-guide/edit_profile_1.png)

Select My Profile from the drop down menu

![edit profile 2](/images/user-guide/edit_profile_2.png)

Navigate to the Management button in the top right hand corner, and select edit profile from the drop down menu

![edit profile 3](/images/user-guide/edit_profile_3.png)

The fields you can edit are straightforward and include:

* First Name
* Last Name
* ORCID Identifier
* Description
* Contact details
* Knowledge and expertise
* Project positions
* Email announcements
* subscriptions


## Managing your account

To manage your account you need to navigate to your profile in the top right hand corner for SEEK 

![edit profile 1](/images/user-guide/edit_profile_1.png)

Select My Profile from the drop down menu

![edit profile 2](/images/user-guide/edit_profile_2.png)

Navigate to the Management button in the top right hand corner, and select Manage Account from the drop down menu

![manage account 1](/images/user-guide/manage_account_1.png)

You can edit your login details within the interface

![manage account 2](/images/user-guide/manage_account_2.png)



## Adding assets (data, models, SOPs, publications) to SEEK

To add a data file to SEEK, select Create from the menu bar, and select the appropriate asset from the drop down menu.

![add data 1](/images/user-guide/add_data_1.png)

To add a local file you need to select Choose File

![add data 2](/images/user-guide/add_data_2.png)

To add assets stored elsewhere, including other databases, select Remote URL

![add data 3](/images/user-guide/add_data_3.png)

SEEK will show a preview of the link

![add data 4](/images/user-guide/add_data_4.png)


Assets in SEEK can be described using a number of fields:

* [Title](#title)
* [Description](#description)
* [Projects](#projects)
* [Sharing](#sharing)
* [Tags](#tags)
* [Attributions](#attributions)
* [Contributors](#contributors)
* [Publications](#publications)
* [Experimental assays and Modelling analysis](#experimental assays and Modelling analysis)
* [Events](#events)

## Generating the ISA structure
The ISA (Investigation, Study, Assay) is a general purpose framework for describing how experiments relate to one another. For more information you can look at our ISA best practice guide.

### Creating an investigation
The investigation is a high level concept that links related studies. To generate an Investigation select Investigation from the create menu at the top of the SEEK.

![create investigation 1](/images/user-guide/create_investigation_1.png)

An investigation is described and linked using the following fields:

* [Title](#title)
* [Description](#description)
* [Projects](#projects)
* [Sharing](#sharing)
* [Contributors](#contributors)
* [Publications](#publications)


### Creating a study
A study is a particular biological hypothesis or analysis. Multiple studies can be connected to an investigation. To generate a Study select Study from the create menu at the top of the SEEK.

![create study 1](/images/user-guide/create_study_1.png)

A study is described and linked using the following fields:

* [Title](#title)
* [Description](#description)
* [Experimentalists](#experimentalists)
* [Investigation details](#investigation-details)
* [Contributors](#contributors)
* [Sharing](#sharing)
* [Publications](#publications)

### Creating an experimental assay
An assay is in general an experiment that converts either a material or data sample, into a new material or data sample, via a protocol. Multiple assays can be connected to a Study. Experimental assays refer specifically to laboratory assays. You can select to make an experimental assay by selecting assay from the create menu at the top of the SEEK. 

![create assay 1](/images/user-guide/create_assay_1.png)

You can then choose an assay type. Select experimental assay. 

![create assay 1](/images/user-guide/create_assay_2.png)

A experimental assay is described and linked using the following fields:

* [Title](#title)
* [Description](#description)
* [Study](#study)
* [Assay Type](#assay-type)
* [Technology Type](#technology-type)
* [Organisms](#organisms)
* [Contributors](#contributors)
* [Sharing](#sharing)
* [Tags](#tags)
* [Contributors](#contributors)
* [SOPs](#sops)
* [Data Files](#data-files)
* [Publications](#publications)

### Creating a modelling analysis
An assay is in general an experiment that converts either a material or data sample, into a new material or data sample, via a protocol. Multiple assays can be connected to a Study. Modelling analysis refer specifically to simulations (in silico experiments) of models. You can select to make an modelling analysis by selecting assay from the create menu at the top of the SEEK. 

![create assay 1](/images/user-guide/create_assay_1.png)

You can then choose an assay type. Select modelling analysis. 

![create assay 1](/images/user-guide/create_assay_2.png)

A modelling assay is described and linked using the following fields:

* [Title](#title)
* [Description](#description)
* [Study](#study)
* [Biological Problem Addressed](#biological-problem-addressed)
* [Organisms](#organisms)
* [Contributors](#contributors)
* [Sharing](#sharing)
* [Tags](#tags)
* [Contributors](#contributors)
* [SOPs](#sops)
* [Data Files](#data-files)
* [Publications](#publications)


## Generic linking variables in SEEK

### Title
You should make titles as descriptive as possible.

### Description
The description allows you to further expand important details. 

### Projects
Assets can be assigned to projects in which they were created using the drop down menu.
![add project 1](/images/user-guide/add_project_1.png)

You can remove any selected projects using the remove button.
![add project 2](/images/user-guide/add_project_2.png)

### Investigation details

### Study
[Assay specific] You can link an assay to a particular study within your projects using the drop down menu. 

### Biological Problem Addressed
[Assay specific - modelling analysis] You can select which biological problem is addressed with the modelling analysis using the drop down menu. You can also add you own using the new modelling analysis type button.

![Biological problem addressed 1](/images/user-guide/biological_problem_addressed_1.png)

### Assay Type
[Assay specific - experimental assay]
You can select an assay type from the drop down menu, or where appropriate create a new assay type using the new assay type button.

![Assay Type 1](/images/user-guide/assay_type_1.png)

### Technology Type
[Assay specific - experimental assay]
You can select a technology type from the drop down menu, or where appropriate create a new technology type using the new technology type button.

![Technology Type 1](/images/user-guide/technology_type_1.png)

### Organism 
[Assay specific]
You can select an organism from the drop down menu. 

![organism 1](/images/user-guide/organism_1.png)

### Experimentalists


### Sharing
SEEK has fine grained sharing permissions. You can choose to share an asset in SEEK with just you, selected people within and outside of SEEK, your whole project, or publicly.

### Tags
Tags are key words that are relevant in some way to the asset and its properties. They are used so relevant assets can be found more easily by other users using key-word searches. To incude a tag you just type it into the box. Suggestions of tags will appear in a drop down menu as you type. You are free to use any free text for tags.  

![add tags 1](/images/user-guide/add_tags_1.png)

### Attributions
An attribution in SEEK allows you, where appropriate, to select the asset from which your asset was derived from (stored within SEEK). As you type in the attribution, related assets will appear in a drop down menu. 

![add tags 1](/images/user-guide/add_attribution_1.png)

### Contributors
Contributors are others who have been involved in generating the asset, through for example planning, experimentation, or analysis.  

![add contributor 1](/images/user-guide/add_contributor_1.png)

You can add multiple contributors, either one by one.

![add contributor 1](/images/user-guide/add_contributor_1.png)

or using the add multiple project members tab, where you select members of a specific project to add.

![add project members 1](/images/user-guide/add_project_members_1.png)

You can choose to add all member of a project, or members of a project from a specific institution.

![add project members 2](/images/user-guide/add_project_members_2.png)

You can also include non-SEEK creators.

You can also add non-SEEK contributors using free text. 

![add non-SEEK contributors 1](/images/user-guide/add_nonseek_contributors_1.png)

Contributors can be removed easily where necessary. 

![add project members 3](/images/user-guide/add_project_members_3.png)

### SOPs 
[Assay specific]
SOPs are standard operating procedures which describe the protocol required to reproduce the assay. They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant SOPs can be linked directly to the assay via the dropdown menu. 

### Data Files 
[Assay specific]
Data files can be any file containing data relevant to the assay (raw data, processed data, callibration information etc). They can be in any format (word files, e-lab notebooks, code, annotated spreadsheets etc). Relevant data files can be linked directly to the assay via the dropdown menu. 

### Publications
If your asset is directly related to a publication you can link the two together in SEEK. You can select publications within your project form the drop-down menu. If the publication is in another project you need to check the box that says associate publications from other projects.

![add publication 1](/images/user-guide/add_publication_1.png)

When a publication is added a preview will be shown in the bottom right hand corner of SEEK. It can be removed easily if needed.

![add publication 2](/images/user-guide/add_publication_2.png)

### Experimental assays and Modelling analysis
It is best that assets are contextualised using the ISA graph (more later). This means that assets where possible should be linked to an assay or an experimental analysis. This can be done by selecting an appropriate assay or experimental analysis from the drop down menu. 

![add assay 1](/images/user-guide/add_assay_1.png)

An assay preview will appear on the right hand side of SEEK once selected. The linking can be removed from the asset easily. 

![add assay 2](/images/user-guide/add_assay_2.png)

### Experimental assays and modelling analysis

### Events
If the asset was generated as part of an event that is registered in SEEK, you can link to the asset to the event using the drop down menu. 

![add event 1](/images/user-guide/add_event_1.png)

A preview of the event will appear on the right hand side of SEEK once selected. The link can be removed from the asset easily. 

![add event 2](/images/user-guide/add_event_2.png)

## Making an investigation citable
SEEK allows you to publish investigations, replete with studies and assets that comprise it. You can then assign a DOI to the investigation, which provides a persistent link with which you and others can cite the investigation with. Publishing an investigation involves the following steps:

* [Making public](#making-public)
* [Snapshotting](#snapshotting)
* [Creating a Research Object](#creating-a-research-object)
* [Assigning a DOI](#assigning-a-doi)

### Making public
In order to make an investigation citable it must first be public. In order to make your investigation public, navigate to your investigation, and click the administration button in the top right hand corner of SEEK. Select the publish full investigation button.

![publish investigation 1](/images/user-guide/publish_investigation_1.png)

The investigation may have some studies, assays, and other asset files which are not yet public. You can review the items that are currently not public by selecting OK in the bottom left hand corner of SEEK. Or you can skip the step if you do not want to make anything else public.

![publish investigation 2](/images/user-guide/publish_investigation_2.png)

You will be able to check any currently unpublished assets, and given an option to make them all, or a select few of them, public.

![publish investigation 3](/images/user-guide/publish_investigation_3.png)

You will be informed of which assets you are planning to make public. To make them public you confirm the changes in the bottom left hand corner of SEEK. 

![publish investigation 4](/images/user-guide/publish_investigation_4.png)

### Snapshotting
Once the investigation (at least) is public, a snapshot can be made of the investigation. Investigations are evolving and changing structures in SEEK. A snapshot is a way of freezing a version of the investigation in its current state, so that even if aspects of the investigation change over time, the frozen version can be accessed.

To generate a snapshot you need to select snapshot from the administration button in the top right hand corner of the investigation screen on SEEK. 

![snapshotting 1](/images/user-guide/snapshotting_1.png)

You will be given an inventory of items that will be included and excluded in the snapshot. All non-public items are excluded. You will have to make them public if you want them to be included in the snapshot. If you are happy with the contents of the snapshot you can proceed by clicking make snapshot in the bottom right hand corner.  

![snapshotting 2](/images/user-guide/snapshotting_2.png)

### Creating a Research Object
Now that the snapshot has been taken you can download the snapshot as a research object, by selecting the download button in the top right hand corner of SEEK.

![snapshotting 1](/images/user-guide/snapshotting_1.png)

### Assigning a DOI
Now that the snapshot has been taken you can assign a DOI, which is a persistent identifier, to the snapshot. This allows you to persistently link to the contents of the snapshot, irrespective of whether it is moved to a different location. This allows the snapshot to be used in publications to complement or replace traditional supplementary material. It also allows for citation of your data by other researchers. You can assign a DOI by clicking the DOI button in the top right hand corner.

![snapshotting 1](/images/user-guide/snapshotting_1.png)

Once you generate a DOI, the snapshot will have a DOI logo associated with it, so you know which snapshot it is.

![DOI 1](/images/user-guide/DOI_1.png)

You will also be able to find the DOI link in the snapshots attributes

![DOI 1](/images/user-guide/DOI_2.png)

## Specialist user roles
SEEK has a number of specialist roles that users within a project can be assigned.  The roles are:
* [Asset housekeeper](#asset-housekeeper)
* [Asset gatekeeper](#asset-gatekeeper)
* [Project administrator](#project-administrator)

Here is a summary of the capabilities of each role. 
![Roles 1](/images/user-guide/roles_1.png)

### Asset housekeeper
The Asset Housekeeper has the special ability to manage assets belonging to other people in the project – but only people who have been flagged as having left the project. It is useful to prevent items being "stranded" when somebody leaves a project, but without handing over their assets from the project to be managed by other users. 

### Asset gatekeeper
This is an optional role which allows a specific user or users to have control over whether assets within the project are can be made public. Whenever a project item is made public or published, it will not become available until the Asset Gatekeeper has approved it. The Asset Gatekeeper is notified when an asset is pending publication. It acts as a way of preventing pre-published items becoming publicly available to soon. 

### Project administrator
The Project Administrator gets notified when someone new signs up to the project within SEEK. They also have the ability to:

* [Add and remove people from a project](#add-and-remove-people-from-a-project)
* [Create organisms](#create-organisms)
* [Create profiles](#create-profiles)
* [Create Institutions](#create-institutions)
* [Assign people to project roles](#assign-people-to-project-roles)
* [Flag when a person leaves a project](#flag-when-a-person-leaves-a-project)

#### Add and remove people from a project

#### Create organisms

#### Create profiles

#### Create institutions

#### Assign people to project roles

#### Flag when a person leaves a project
