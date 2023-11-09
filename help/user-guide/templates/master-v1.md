---
title: SEEK User Guide - RightField template v1
layout: page
---

# Metadata Template

## Overview

The metadata sheet in the templates allows some basic information to be collected and recorded along with the data.

The template has been construced using the [JERM Ontology](https://jermontology.org), and built using [RightField](https://rightfield.org.uk).

When uploaded to SEEK this information is then automatically detected and used to populate the form.

The metadata sheet is included with our Samples templates, but can also be used as the first sheet within your own data templates.


## Fields

Below is a description about each of the fields, which has been labelled in the following screenshot:

![metadata fields](/images/user-guide/templates/master-v1-template.png){:.screenshot}

_**1.**_  The title for the Data file entry that will be registered with SEEK

_**2.**_  The description that should be registered for this Data file.

_**3.**_  The full Project SEEK ID<sup>*</sup> that the Data file will be associated with.

_**4.**_  If you wish to link to an existing Assay, this should contain the full Assay SEEK ID<sup>*</sup>.
    
&nbsp;&nbsp;&nbsp;&nbsp; **OR** alternatively, you may want to create a new Assay:
   
_**5.**_  The full Study SEEK ID<sup>*</sup> that the Assay will be associated with.

_**6.**_  The title for the Assay entry that will be created in SEEK

_**7.**_  The description for the Assay entry that will be created in SEEK

_**8.**_  The experimental assay type, which needs to be selected from a list of available options

_**9.**_  The Assay technology type, which needs to be selected from a list of available options

_**10.**_ If you wish to link the Assay to an existing SOP, this should contain the full SOP SEEK ID<sup>*</sup>.

### * SEEK ID's

The SEEK ID should be the full resolvable _persistent identifier_, including the host. This can be found for any item in SEEK, and generally matches
the URL. This isn't always the case though, such as if a SEEK is running with different aliases. For example https://fairdomhub.org/projects/19. 

It can be found near the top of page, under the description.

If the ID used doesn't match the SEEK the template is being uploaded to, a warning will be given and the item ignored.
          