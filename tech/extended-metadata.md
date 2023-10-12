---
title: Extended Metadata Technical Overview
layout: page
---

# Extended Metadata Technical Overview

## Introduction

Extended Metadata is a feature added to SEEK as part of [version 1.11](/tech/releases/#version-1110), originally to support
MIAPPE but designed for future use. 
It provides the ability to define additional metadata attributes for a particular type, to support a particular standard (i.e MIAPPE).

<div class="alert alert-warning" markdown="1">
It was originally referred to as 'Custom Metadata' but the renamed to avoid confusion, as the metadata can only be extended but not entirely customised. 
You may sometimes hear or read it referred to as Custom Metadata, and they are the same thing.
</div>

It is not a feature a user would directly see, other than revealed through extensions that are made available:

![](/images/user-guide/extended-metadata/extended-metadata-select.png){:.screenshot}

... will reveal new fields below:

![](/images/user-guide/extended-metadata/extended-metadata-fields.png){:.screenshot}

The attributes can be associated with a particular attribute type, and marked as optional or mandatory, and will be validated against. This is very similar to Samples.

Extended metadata will only be shown if defined within the database, which is currently the only way of configuring it.


## How it works

Extended Metadata works in a very similar way to Samples, and shares a lot of the same code. Extended Metadata Types are defined, that describe a set of attributes with names
and point to a SampleAttributeType to define the attribute type. The Extended Metadata type is also linked to a particular resource type in 
SEEK (**currently only Investigation, Study and Assays are supported**, but this is currently being extended).

You can think of Extended Metadata being a Sample, but instead of standing alone is embedded within another type to extend it's metadata.
This is explained in the following high level representation.

![](/images/user-guide/extended-metadata/high-level-arch.png){:.screenshot}

Currently, Extended Metadata can only be defined by directly making entries in the database. 
This is generally done through a seed file, for example the [MIAPPE Extended Metadata Seed](https://github.com/seek4science/seek/blob/main/db/seeds/008_miappe_custom_metadata.seeds.rb).
By default only MIAPPE is provided, but other bespoke installations have used the ability to extend their own metadata, e.g. for ENA. We hope to include this as a pre-installed option in the future.

We are planning on making it easier for an instance administrator to define Extended Metadata themselves, initially through simple JSON or an Excel template, and then longer term through a user interface.

If you have a metadata scheme that you think is in a mature state and would like to be added as a default installation,
or need help adding to your own instance, then please [contact us](/contacting-us)

This is something we've been rolling out slowly and carefully, after initially using internally, because once defined and populated they are difficult to redefine.

 