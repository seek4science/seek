---
title: SEEK User Guide - Create Samples Type
layout: page
---

# Create a Sample Type

Sample Types are templates that detail the key information that needs to be included to describe a given sample correctly.

By default, any member of a Project may create a Sample Type and associate with that Project. By default the Sample Type will only be visible to members of that
 project until it has publicly accessible Samples associated with it. See [Sample Type Visibility](#sample-type-visibility) .

A SEEK Administrator can change the configuration such that Sample Types can only be created by the Project Administrator.


To create a new sample type, select create from the drop down menu, and then select Sample Type from the list

![menu create sample type](/images/user-guide/samples/menu-create-sample-type.png){:.screenshot}

A Sample Type can be made in two ways

* By manually defining the attributes using a form
* Uploading a spreadsheet that contains a Sample Template.




## Creating a Sample Type manually using a Form

First we will show generating a Sample type through manually creating a sample type. To begin with ensure that the Form is selected.

![sample type form](/images/user-guide/samples/sample-type-form.png){:.screenshot}

Sample Type allows you to include:
 
* [Title](general-attributes.html#title)
* [Description](general-attributes.html#description)
* [Projects](general-attributes.html#projects)
* [Tags](general-attributes.html#tags)


You can define your own attributes for the Sample Type. 
We would recommend using Minimum Information Checklists to assist in deciding the attributes you will need to include in your Sample Type.

## Defining Attributes

All attributes must have a Name, and a selected Type. 


You can define the different types of data that the attributes should be:


* **String**: a sequence of characters (e.g Blue)
* **Text**: A longer alphanumerical entry (e.g. The 4th experiment in the batch, it was sampled late, so may not be as accurate). 
* **Integer**: a whole number; not a fraction (e.g. 1, 2, 3, 4)
* **Date**: A selected date (e.g. 2nd December 2016)
* **Date time**: a selected date and time (e.g. 2nd December 2016 at 14:00 GMT)
* **Real number**: A number that can be a fraction and include a decimal place, e.g 1.25
* **Web link**: a link to a specific web page (e.g. https://fair-dom.org)
* **Email address**: e.g. support@fair-dom.org
* **CHEBI ID**: An identification for a specific chemical structure registered in the ChEBI database (https://www.ebi.ac.uk/chebi/) (e.g. CHEBI:17234)
* **Boolean**: a true/false declaration, 1 or 0 can also be accepted.
* **SEEK strain**: an internal link to a strain registered within SEEK. 
* **SEEK sample**: an internal link to a sample registered within SEEK.  
* **URI**: A Uniform Resource Identifier, which for example may relate to an ontology term
* **Controlled Vocabulary**: An attribute can be a set of predefined terms you have to select from, and any other term is invalid. You can either create a new 
controlled vocabulary or reuse and existing one. In the future we will be adding ontology support the the controlled vocabularies.

![sample type attributes](/images/user-guide/samples/sample-type-attributes.png){:.screenshot}

The attribute type selected dictates the value would be accepted, and also influences how it is displayed for the Sample

If you feel an attribute type is missing, it can usually be easily added so please [Contact Us](/contacting-us.html)

At least one of the attributes must be required and marked as the title. This is the attribute shown in certain views or lists within SEEK.
Other attributes can be also be marked as required if need be.

![sample type attributes required](/images/user-guide/samples/sample-type-attributes-required.png){:.screenshot}

Once completed click update. Your Sample Type can now be used to generate Samples.

## Creating a Sample Type from a template

A sample type can also be generated from your own Excel template. The sample type will be based upon the first sheet with a
name containing _sample_, and the attributes will be based on the column heading in the first row.

When creating the sample type, first choose the tab _Use spreadsheet template_


On the initial Sample Template page you can include the following metadata:
 
* [Title](general-attributes.html#title)
* [Description](general-attributes.html#description)
* [Projects](general-attributes.html#projects)
* [Tags](general-attributes.html#tags)
 
and then also select Choose File to select a sample template to upload:

![sample type from template](/images/user-guide/samples/sample-type-from-template.png){:.screenshot}


Once a template is selected, and the appropriate metadata is added, select Create. 
From here you will be taken to a page containing the metadata, and a list of the attribute names from the template file.

Here you can select specific attribute types (the default it String). You are also free to delete, rename or reorder the attributes.
At least one attribute must be required and set to the title, and other attributes can be marked as required if need be.

![sample type attributes from template](/images/user-guide/samples/sample-type-attributes-from-template.png){:.screenshot}

Once completed click update. Your Sample Type can now be used to generate Samples.

## Sample Type Visibility

Initially, a Sample Type is only visible and accessible to members of the Project it is associated with.

However, once a Sample Type has instances of Samples associated with them, and those Samples are shared publically (i.e. to logged out members), the Sample Type
also becomes visible.

When a Sample is shared outside of a Project, but is still not accessible publicly, then the Sample Type will adopt the visibility of the referring Sample
when accessed via a link. For example if a Sample is shared with another Project, a member of that other Project may view the Sample Type when clicking the link
the link from the Sample description. However, in this case, the Sample Type won't appear in lists or search results.

## Editing Sample Types

The Sample Type may be edited by the original creator, or somebody that can administer the related projects.

If no samples have yet been created, you can freely edit the Sample Type and its attributes. Once Samples have been created for a Sample Type, it is no longer possible to modify the attributes - however other details about the Sample Type can be changed.
 

For details on how to create a Sample please go to [Creating a Sample](create-sample.html) 


