---
title: SEEK User Guide - Roles
layout: page
---


# Specialist user roles
SEEK has a number of specialist roles to which users can be defined

Programme specific roles:

* [Programme administrator](#programme-administrator)

Project specific roles:

* [Asset housekeeper](#asset-housekeeper)
* [Asset gatekeeper](#asset-gatekeeper)
* [Project administrator](#project-administrator)

Here is a summary of the capabilities of each role.
![Roles 1](/images/user-guide/roles_1.png)

## Programme administrator

A programme administrator looks after an entire Programme. They have the ability to assign other Programme administrators to their Programme, but cannot remove themself. To remove themself they first need to assign another administrator and ask them to do so for them, this is to prevent a Programme accidentally becoming without an administrator.
Any other SEEK user can be made a Programme administrator.

A Programme administrator also has the ability to create Projects, which will become automatically assigned to their Programme. Although they will not automatically become the [Project administrator](roles.html#project-administrator) or member of that Project, there is an option to do so by selecting the Institution.

To create a Project you can do so from the Create menu at the top of the page. Your Programme must first have been [accepted and activated](programme-creation-and-management.html#creating-a-programme).
Once created you can also provide a logo or picture by clicking change picture under the picture on the right of the Project page.
A Programme administrator also has some of the abilities of a Project Administrator:

* [Add and remove people from a project](#add-and-remove-people-from-a-project)
* [Create organisms](#create-organisms)
* [Create profiles](#create-profiles)
* [Create Institutions](#create-institutions)

## Asset housekeeper
The Asset Housekeeper has the special ability to manage assets belonging to other people in the project – but only people who have been flagged as having left the project. It is useful to prevent items being "stranded" when somebody leaves a project, but without handing over their assets from the project to be managed by other users.

To become an Asset housekeeper you must also be a member of that Project.

## Asset gatekeeper
This is an optional role which allows a specific user or users to have control over whether assets within the project are made public. Whenever a project item is made public or published, it will not become available until the Asset Gatekeeper has approved it. The Asset Gatekeeper is notified when an asset is pending publication. It acts as a way of preventing pre-published items becoming publicly available to soon.

To become an Asset gatekeeper you must also be a member of that Project.

## Project administrator
The Project Administrator gets notified when someone new signs up to the project within SEEK. They also have the ability to:

* [Add and remove people from a project](#add-and-remove-people-from-a-project)
* [Create organisms](#create-organisms)
* [Create profiles](#create-profiles)
* [Create Institutions](#create-institutions)
* [Assign people to project roles](#assign-people-to-project-roles)
* [Flag when a person leaves a project](#flag-when-a-person-leaves-a-project)

They can also edit the Project details, along with Institutions associated with the Project.

To become a Project Administrator you must also be a member of that Project.

### Add and remove people from a project

Part of administering a project will involve adding to or removing people from it. You can do this if you are a [Project Administrator](#project-administrator) or you are
a [Programme Administrator](#programme-administrator) of a Programme that Project falls under.

Before adding people to the project, you should check that their [profiles](#create-profiles) and [Institutions](#create-institutions) have been created first.

From the Administer menu on the Project page, select "Administer Project Members". There are some explanations on that page. To add people you type their name in the right hand panel, and also select the Institution they are associated with for this Project from their list. You can add multiple people to an
institution in one action.

Don't forget to confirm the changes with the Confirm button when finished.


### Create organisms

To create an organism, choose Organism from the Create menu at the top of the page.

An Organism can just have a title, but preferably also include the NCBI taxonomy URI. To make this easier there is an option to search for the organism, and then click the result to automatically add the name and taxonomy URI.

*Note, if you are running your own installation of SEEK, the search is only available if you have [registered with BioPortal](https://bioportal.bioontology.org/accounts/new) and created an API key. The API key needs to be set under the Server Admin area - under Site configuration, Additional settings.*

### Create profiles

It is possible to create profiles for people that have not registered with SEEK. This is useful if you want to describe and credit members of your Project who are not yet SEEK users. They can adopt their profile later during [Registering](registering.html).

To create a profile, choose Profile from the Create menu at the top of the page. The first and last name are required, and also the email address. The email address must be unique to SEEK.

### Create institutions

To create an Institution, choose Institution from the Create menu at the top of the page.

The title and country are required, and the title must be unique to SEEK. It is recommended that you provide as much detail as you can. Once created you can also provide a logo or picture by clicking change picture under the picture on the right of the Institution page.


### Assign people to project roles

As a [Project Administrator](#project-administrator) (or SEEK system administrator) you can assign people to roles. From the Administer menu on the project page select "Administer project member roles". To add to each role start to type the name of the person. You can remove by clicking the 'x' next to their name.

The people must be first have been [added to the project](#add-and-remove-people-from-a-project) before they can be assigned to a role.


### Flag when a person leaves a project

*Coming soon*

