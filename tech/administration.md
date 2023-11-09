---
title: adminstration
layout: page
redirect_from: "/administration.html"
---

# Administration of SEEK

Here are described some basic administration tasks you may want to do after
installing SEEK. All admin tasks can be found in the Admin area, by selecting
the Account tab, and then selecting Server Administration. Many of the
settings have a description of what they do and are not covered here.

## Creating a Project and Institution

Before you can add items, such as Data files or Models, to SEEK, you need to
create the first Project and Institution and add yourself to them.

You can first create your Project and Institution from the Common Tasks in the
admin area.

Once these have been created, you need to link the Project to the Institution,
by navigating to the Project show page and clicking the Project administration
button. From this page you can select one or more Institutions for this
Project, and then saving by clicking the Update button at the bottom of the
form.

You can add yourself to the Project and Institution you have created, by
navigating to your profile, selecting Person administration, and then
selecting the Project/Institution pair from the list, and clicking the Update
button at the bottom of the form.

Note that, Projects can be associated with multiple Institutions, and People
can belong to multiple Project/Institution pairs. When selecting multiple
items from the lists you need to hold CTRL as you select them.

## Configuring Email

By default email is disabled, but if you are able to you can configure it to
enable SEEK to send emails - such are emails about changes within your
project, notification emails, feedback emails and notifications about errors.
You can configure email under Admin->Configuration->Enable/disable
features. Part way down that page there is a checkbox "Email enabled" that you
should select. This reveals some SMTP settings that you need to fill out. Any
that are not needed can be left blank. The meaning of the settings are:

*   Address - the address (name or IP address) of the SMTP server used to
    deliver outgoing mail
*   Port - the port that your mail server receives mail
*   Domain - if you need to specify a HELO domain, you can do it here.
*   Authentication - if your mail server requires authentication, you need to
    specify the authentication type here. This can be *plain* (will send the
    password in the clear), *login* (will send password Base64 encoded) or in
    rare cases *cram_md5*
*   Auto STARTTLS enabled - enable this is your mail server requires Tranport
    Layer Security, and you get STARTTLS errors when testing your
    configuration
*   User name -  if your mail server requires authentication, set the username
    in this setting.
*   Password - if your mail server requires authentication, set the password
    in this setting


There is a box beneath here that you can use to test your settings. Also, if
you wish to receive emails about errors that occur - then you can check the
box for Exception notification enabled, and supply a list of email addresses
below (comma or space seperated).

## Configuring BioPortal

[BioPortal](https://bioportal.bioontology.org/) is a service used in SEEK for
supporting and searching ontologies, which we communicate with via its API.
However, the API requires an api-key that we are unable to distribute with
SEEK. To be able to link organisms with NCBI terms, or search for organisms
when defining new ones, an api-key has to be setup. We also have future plans
for more widespread uses of ontologies - such as for the Assay and Technology
types, and for tagging with semantic terms.

To get an api-key you first need to register with BioPortal at
https://bioportal.bioontology.org/accounts/new, and once registered and logged
in your api-key should be shown under Account details. More information is
available at
https://www.bioontology.org/wiki/index.php/BioPortal_REST_services.

In SEEK, you apply the BioPortal api-key under the Admin->Configuration->Settings.

## Configuring DOI and PubMed search

To be able to support adding publications using a
[PubMed](https://www.ncbi.nlm.nih.gov/pubmed) ID or DOI to your SEEK
installation, you need to do 2 things.

*   For PubMed you simply need to add your email address under Admin->Configuration->Settings
*   For DOI - you need to register your email address with
    [CrossRef](https://www.crossref.org/) at
    https://www.crossref.org/requestaccount/ and then provide that email to
    SEEK under Admin->Configuration->Settings

## Configuring Session Store Timeout

The timeout period is set to 1 hour by default. This means that a user may be logged out after 1 hour, if they haven't selected "Remember Me"
when logging in, and could lead to lost information if spending a long time filling out a form.

Usually, 1 hour is sufficient, but the timeout can be updated under Admin->Configuration->Settings.


