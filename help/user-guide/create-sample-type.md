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
* **Web link**: a link to a specific web page (e.g. http://fair-dom.org)
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

Sample Type visibilty and accessibility to users can be defined by registered users with managing rights over the Sample Type via the [sharing permission](general-attributes.html#sharing).

## Editing Sample Types

A Sample Type can only be edited by registered users that have the permission to edit a specific Sample Type. See [sharing](general-attributes.html#sharing) and [bulk changing of sharing permission](bulk-change-sharing-permission.html) for more information about how to manage sharing permission.

Select the Sample Type, then select the "Actions" button and click on "Edit Sample Type".

### Adding a new attribute as optional

Optional attributes can be added to a Sample Type.

You can define your own attributes for the Sample Type. See "Creating a Sample Type manually using a Form" paragraph above.
All attributes must have a Name, and a selected Type. See the "Defining Attributes" paragraph above.

If existing samples have been previosly created using the Sample Type you want to add attributes to, those samples will also show the newly added optional attributes with empty values by default.

Users with editing rights over those samples should decide whether to assign values to the added optional attributes for the existing samples or not. <!--See editing samples: info missing-->


### Adding a new attribute as mandatory

A new mandatory attribute can be added to a Sample Type via the following steps:
1. Add the new attribute to the Sample Type as optional (do not select "Required?") and Save the change by clicking "Update" button.
2. Select the Sample Type and then click on the "View samples" button.
3. Locate the newly added attribute you want to make required and ensure that all samples have values in it. 
* If you have permission to edit those samples,[edit the samples]() by assigning values for the attribute of interest.
* If you don't have the permission to edit all the samples, make sure to contact the creator(s) and/or the submitter of those samples, and ask them to add values for the new optional attribute. 

Note that all samples, including the ones that might not be visible to you, must have values for the attribute of interest, otherwise the intended change cannot be made.

3. Select the Sample Type, then select the "Actions" button and click on "Edit Sample Type" from the dropdown menu. Locate the attribute you want to make required and select the checkbox next to "Required?" to make it a mandatory field. Save the changes to the Sample Type by clicking the "Update" button.


### Making an optional attribute mandatory

Optional attributes in a Sample Type can be made mandatory via the following steps:
1. Select the Sample Type and then click on the "View samples" button.
2. Locate the attribute you want to make required and ensure that all samples have values in it. 
* If you have permission to edit those samples,[edit the samples]() by assigning values for the attribute of interest.
* If you don't have the permission to edit all the samples, make sure to contact the creator(s) and/or the submitter of those samples, and ask them to add values for the new optional attribute. 

Note that all samples, including the ones that might not be visible to you, must have values for the attribute of interest, otherwise the intended change cannot be made.

3. Select the Sample Type, then select the "Actions" button and click on "Edit Sample Type" from the dropdown menu. Locate the attribute you want to make required and select the checkbox next to "Required?" to make it a mandatory field. Save the changes to the Sample Type by clicking the "Update" button.


### Editing existing attributes without causing technical conflicts with samples' values

You can edit existing attributes of a Sample Type in the following ways, without causing technical conflicts that would trigger validation errors for samples' values in the system.
* Change a mandatory attributes to optional: deselect the checkbox "Required?"
* Edit the Name
* Edit what attribute is a Title: tick the checkbox "Title?" for a different attribute
* Edit the Description
* Edit the link to the PID
* Edit the Unit

Although it is possible to apply such changes, it's important to ensure that any modifications do not create semantic inconsistencies with the data that has already been collected for the existing samples. For instance, if you change the name or description of an attribute, this could cause confusion or difficulty in interpreting data that has already been collected for that attribute. Therefore, it's important to carefully consider the potential impact of any changes to existing attributes of a Sample Type, and to make sure that these changes are made in a way that does not create semantic inconsistencies or confusion with the values of existing samples.


### Editing an existing attribute in a way that may create technical conflict with samples' values
Work in progress. It will include editing and deleting of:
* attributes
* attribute types
* controlled vocabulary and ontologies

<!-- pseudocode
1. Edit sample type with linked samples
2. Make attribute mandatory or edit existing (type, CV, mandatory)
3. Hit save
4. SEEK checks all samples for conflict
  a. No conflicts: saved
  b. Conflicts: meaningful error message
    i. Explain what is the change that causes conflicts, when multiple changes are made at the same time
    ii. Issues in showing samples?
Give the user option to define a default value or PLACEHOLDER for non compliant samples (ALL of them)

Delete 
First check: has the user the permission to edit the linked samples?
How adding and deleting attribute affect samples originated from data file (spreadsheet template)? It doesn't because spreadsheet template/datafile will not be so tightly linked to extracted samples anymore.

-->
