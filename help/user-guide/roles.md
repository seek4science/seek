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
This is an optional role, which allows a specific user or users to have control over whether assets within the project are made public or not.
It is a way of preventing pre-published items becoming publicly available to soon.

Whenever a user attempts to *publish* an asset, a request is sent to the Asset Gatekeeper.
The asset will not become available until the Asset Gatekeeper has approved it.

To become an Asset gatekeeper the user must also be a member of that Project.

___

### When is the gatekeeper involved?

The gatekeepers only control the **Public** access of an item,
and their approval is only required when *publishing* an item.

An item is only considered *published* if its **Public** sharing permissions are set to:
- **View** if the item is not downloadable (Investigations, Studies, Assays...).
- **Download** if the item is downloadable (SOPs, Documents, Data Files...)

Note that this means that *downloadable* items can be set to **View** without involving the gatekeeper.

It also means that *permissions* can be extended to individuals or groups without involving the gatekeeper.

### How do I request to publish an asset?

Requests are automatically sent to the gatekeeper when an item is attempted to be published.
This applies both to new and pre-existing assets.

Assets can be published individually through the "Publish" button in the asset's actions menu,
or by managing the asset and changing its **Public** sharing permissions to a published status (see above).

They can also be published in bulk, via the "Publish your items" or "Batch permission changes" buttons in your user profile.
The same sharing permission rules for considering an item as published apply.

When you attempt to publish an asset, you will be shown a notice about the gatekeeper being notified.

### How can the gatekeeper approve or reject a request?

Gatekeepers can access a list of publishing requests from their user profile
(through the "Assets you are Gatekeeping" button).
Gatekeepers are granted permission to view the asset in question (if they don't already have it),
so that they can decide whether to approve or reject the request.
They can also opt to add a comment to the requester, for example to explain why a request was rejected.

If rejected, the asset remains unpublished and a notification is sent to the requester,
along with the gatekeeper's comments.
If approved, the asset is immediately made available, and the requester is notified.

### How can I keep track of my publishing request?

You can access a list of the items you have requested to be published from your user profile
(through the "Assets awaiting approval" button).
This allows you to monitor whether the gatekeeper has made a decision on your items or not.
If an item was rejected, you will be able to see the gatekeeper's comments from this list.

While your item is waiting approval from the gatekeeper, or if it has been rejected,
you will also see a warning that indicates the state on the asset's page.
The warning will disappear when the request is approved (or if you cancel the request).

### Can I cancel a publishing request?

Yes. The list of assets awaiting approval includes a button to do so.

Alternatively, you can cancel your request from the asset's actions menu,
or from the button shown above the sharing permissions table in the asset's manage view.

___

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




