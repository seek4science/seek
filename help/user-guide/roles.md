---
title: SEEK User Guide - Roles
layout: page
---


# Specialist user roles
SEEK has a number of specialist roles to which users can be assigned 

Programme specific roles:

* [Programme administrator](#programme-administrator)

Project specific roles:

* [Asset housekeeper](#asset-housekeeper)
* [Asset gatekeeper](#asset-gatekeeper)
* [Project administrator](#project-administrator)

Here is a summary of the capabilities of each role.

![Roles 1](/images/user-guide/roles_1.png){:.screenshot}

## Programme administrator

A programme administrator looks after an entire Programme. They have the ability to assign other Programme administrators to their Programme, but cannot remove themself. To remove themself they first need to assign another administrator and ask them to do so for them, this is to prevent a Programme accidentally becoming without an administrator.
Any other SEEK user can be made a Programme administrator.

A Programme administrator also has the ability to create Projects, which will become automatically assigned to their Programme. Although they will not automatically become the [Project administrator](roles.html#project-administrator) or member of that Project, there is an option to do so by selecting the Institution.

To create a Project you can do so from the Create menu at the top of the page. Your Programme must first have been [accepted and activated](programme-creation-and-management.html#creating-a-programme).
Once created you can also provide a logo or picture by clicking change picture under the picture on the right of the Project page.
A Programme administrator also has some of the abilities of a Project Administrator:

* [Add and remove people from a project](administer-project-members.html#add-and-remove-people-from-a-project)
* [Create organisms](adding-admin-items.html#creating-organisms)
* [Create profiles](adding-admin-items.html#creating-profiles)
* [Create Institutions](adding-admin-items.html#creating-institutions)

## Asset housekeeper
The Asset Housekeeper has the special ability to manage assets belonging to other people in the project – but only people who have been flagged as having become inactive in the project. It is useful to prevent items being "stranded" when somebody leaves a project, but without handing over their assets from the project to be managed by other users.

To become an Asset housekeeper the user must also be a member of that Project.

## Asset gatekeeper
This is an optional role in project, which allows a specific user or users to have control over whether assets and items is general within the project are made public or not.
It is a way of preventing not-published items from becoming publicly available to soon.

To become an asset gatekeeper in a project the user must also be a member of that Project.

Whenever a user attempts to *publish* an item in a project with an asset gatekeeper, a request is sent to the asset gatekeeper.
The item will not become available until the asset gatekeeper has approved it.


### Approving or rejecting a request to publish items

Gatekeepers can access a list of publishing requests by clicking the menu "My profile" and then the button "Assets you are Gatekeeping".

![gatekeeper gatekeeping](/images/user-guide/gatekeeper_gatekeeping.png){:.screenshot}

Gatekeepers are granted permission to view the items in question (if they don't already have it),
so that they can decide whether to approve or reject the request.
They can also opt to add a comment to the requester, for example to explain why a request was rejected.

If rejected, the item remains unpublished and a notification is sent to the requester,
along with the gatekeeper's comments.

If approved, the item is immediately made available, and the requester is notified.


### Publishing an item in project with Asset gatekeeper

The gatekeepers only control the **Public** access of an item,
and their approval is only required when *publishing* an item.

An item is only considered *published* if its **Public** sharing permissions are set to:
- **View** if the item is not downloadable (Investigations, Studies, Assays...)
- **Download** if the item is downloadable (SOPs, Documents, Data Files...)

Note that this means: 
* *downloadable* items can be set to **View** without involving the gatekeeper
* *permissions* can be extended to individuals or groups without involving the gatekeeper


### Requesting to publish an item for the gatekeeper

Requests are automatically sent to the gatekeeper when an item is attempted to be published.
This applies to both items that have been created before and after the gatekeeper has been assigned to a project.


### Keeping track of your own publishing requests

You can access a list of the items you have requested to be published by clicking the menu "My profile" and then the button "Assets awaiting approval".

![gatekeeper awaiting approval](/images/user-guide/gatekeeper_awaiting_approval.png){:.screenshot}

This allows you to monitor whether the gatekeeper has made a decision on your items or not.
If an item was rejected, you will be able to see the gatekeeper's comments from this list.

While your item is waiting for approval from the gatekeeper, or if it has been rejected, you will also see a warning that indicates the status on the asset's page.
The warning will disappear when the request is approved or if you cancel your request.


### Cancelling your own publishing request

You can cancel the publishing request in many ways:

* Via the list of "Assets awaiting approval" under "My profile", which includes the button "Cancel this request".

* Alternatively, you can cancel your request from the item's Actions menu, which will show the "Cancel publishing request" option.

* Or via the "Manage" option under the item's Actions menu, using the "Cancel request" button shown above the sharing permissions table.


## Project administrator
The Project Administrator gets notified when someone new signs up to the project within SEEK. They also have the ability to:

* [Add and remove people from a project](administer-project-members.html#add-and-remove-people-from-a-project)
* [Create organisms](adding-admin-items.html#creating-organisms)
* [Create profiles](adding-admin-items.html#creating-profiles)
* [Create Institutions](adding-admin-items.html#creating-institutions)
* [Assign people to project roles](administer-project-members.html#assign-people-to-project-roles)
* [Flag when a person becomes inactive a project](administer-project-members.html#flag-when-a-person-becomes-inactive-in-a-project)

They can also edit the Project details, along with Institutions associated with the Project.

To become a Project Administrator the user must also be a member of that Project.




