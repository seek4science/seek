---
title: SEEK User Guide - openBIS
layout: page
---

# Using SEEK with openBIS

## Connecting your project to an openBIS space

**Only a Project Administrator may configure connected spaces**

To connect a space from an openBIS instance, you need to select *Administer openBIS* from the project administer menu, as shown
below

![admin openbis menu](/images/user-guide/openbis/admin-openbis-menu.png){:.screenshot}

From here you will see a list of the currently registered openBIS instances and spaces, and also an button at the top giving the option
to connect a new space. 

When connecting a space, you will need to provide some fields. 

  * **Main Web URL** - this is the url to the front page of the openBIS you wish to connect to. When filling out this the field, the following 2 fields will be automatically populated with the default values.
  * **Application Server Endpoint** - this is the endpoint URL SEEK needs to use to query the openBIS server. If you are not sure what this is then stick with the default derived from the main web url.
  * **DataStore Server Endpoint** - this is the endpoint URL that SEEK needs to use to access the data on the openBIS server. If you are not sure what this is then stick with the default derived from the main web url.
  * **Username** - the openBIS user account that SEEK will use to access the openBIS space. You may need to make a dedicated openBIS user that is given access to the space.
  * **Password** - the password for the openBIS user account provided above.
  * **Automated Refresh Period** - in hours, this this is how often SEEK will automatically synchronise metadata from the openBIS space.

Once the above information is provided, click *Fetch spaces*. This will check the above details and check the authentication. If the check is successful, the available spaces will be listed for selection.

Default sharing permissions can also be defined for the space. These are the permissions used when registering a DataSet with SEEK. Once registered, it is possible to change these permissions just like any other dataset.

## Browsing DataSets for a space

Once spaces have been connected to a project, they can be browsed by other members of that project. On the project page, a *Browse openBIS* button will become available.

Once selected, a space will be opened and its contents shown in SEEK. If there is no cache yet available, or the cache has been reset this may take a short while depending on the number of DataSets.

The shown space can be changed by selecting the desired space at the top of the page.

The available DataSets are shown as cards, as shown below. By default already registered DataSets are not shown, but can be displayed by unchecking the *Hide registered* checkbox.

![browse openbis space](/images/user-guide/openbis/browsing-space.png){:.screenshot}

Each card provides some details, along with the number of files - clicking the Files link will show the files contained by that DataSet.

## Registering a DataSet

A DataSet can be registered with SEEK simply by clicking the *Register with SEEK* link. When registered you will be redirected to the new DataFile in SEEK.
This DataFile represents the whole openBIS DataSet including all its files. It can either be downloaded as a single zip file, or individual files can be downloaded via the files link.

The latest synchronised metadata is shown for that DataFile in SEEK. The metadata reflects the current state of the DataSet on openBIS, it is not a copy. 

Currently, if the DataSet is deleted from openBIS the metadata will become unavailable, but the registered DataFile will SEEK will continue to exist.

The DataSet is registered as a DataFile with the default permissions for the space, and the default license for the project.

The DataFile behaves just like any other DataFile in SEEK, and its permissions, license, title, description etc can be changed by the owner or other users with the correct permissions. 
It can also be linked to Assays, Publications and Events. 

In a future version of SEEK we plan to allow registering multiple DataSets in one action.

## Synchronisation

When configuring a space in SEEK, an *Automated Refresh Period* is set which defaults to 2 hours. After each period a process automatically sychronises the latest metadata for both existing and new DataSets. 