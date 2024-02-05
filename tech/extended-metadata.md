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
It was originally referred to as 'Custom Metadata' but recently renamed to avoid confusion, as the metadata can only be extended but not entirely customised. 
You may sometimes hear or read it referred to as Custom Metadata, and they are the same thing.
</div>

It is not a feature a user would directly see, other than revealed through extensions that are made available:

![](/images/user-guide/extended-metadata/extended-metadata-select.png)
{:.screenshot}

... will reveal new fields below:

![](/images/user-guide/extended-metadata/extended-metadata-fields.png)
{:.screenshot}

The attributes can be associated with a particular attribute type, and marked as optional or mandatory, and will be validated against. This is very similar to Samples.

Extended metadata will only be shown if defined within the database, which is currently the only way of configuring it.


## How it works

Extended Metadata works in a very similar way to Samples, and shares a lot of the same code. Extended Metadata Types are defined, that describe a set of attributes with names
and point to a SampleAttributeType to define the attribute type. 

The Extended Metadata type is linked to a particular resource type in SEEK. Currently, it can be incorporated into the following types:
`Collection`, `DataFile`, `Document`, `Event`, `Model`,`Presentation`,`Sop`, `Project`.

You can define the supported resource type as shown below:

```
ExtendedMetadataType.new(title: 'person', supported_type: 'YOUR_TYPE_NAME')
```

You can think of Extended Metadata being a Sample, but instead of standing alone is embedded within another type to extend it's metadata.
This is explained in the following high level representation.

![](/images/user-guide/extended-metadata/high-level-arch.png)
{:.screenshot}

Currently, Extended Metadata can only be defined by directly making entries in the database. 
This is generally done through a seed file, for example the [MIAPPE Extended Metadata Seed](https://github.com/seek4science/seek/blob/main/db/seeds/008_miappe_extended_metadata.seeds.rb).
By default only MIAPPE is provided, but other bespoke installations have used the ability to extend their own metadata, e.g. for ENA. We hope to include this as a pre-installed option in the future.

We are planning on making it easier for an instance administrator to define Extended Metadata themselves, initially through simple JSON or an Excel template, and then longer term through a user interface.

If you have a metadata scheme that you think is in a mature state and would like to be added as a default installation,
or need help adding to your own instance, then please [contact us](/contacting-us)

This is something we've been rolling out slowly and carefully, after initially using internally, because once defined and populated they are difficult to redefine.

 ## Define your own Extended Metadata type 


If you are managing your own SEEK instance, you have the flexibility to define your project-specific Extended Metadata Types by populating the database with a seed file. 

The following are the supported Extended Metadata Attribute Types, each accompanied by a corresponding code snippet for implementation and screenshot in SEEK.

1.**String type**: the attribute refers to a fixed-length character field. (e.g. "blue")

```
 ExtendedMetadataAttribute.new(

    # The attribute's identifier or name (mandatory) .
    title: 'title', 
    
    # Indicates whether this attribute is mandatory for the associated metadata. By default, it is set to false. 
    required: true, 
    
    # Specifies the attribute type, here set to 'String' (mandatory).
    sample_attribute_type: SampleAttributeType.where(title: 'String').first,
    
    # A brief description providing additional details about the attribute. By default, it is set to the empty string. 
    description: 'the title of your study', 
    
    # The label to be displayed in the user interface, conveying the purpose of the attribute. By default, it is set to the value of the 'title' attribute."
    label: 'study title' 
    
)
```
![](/images/user-guide/extended-metadata/atrribute_string_type.png) 
{:.screenshot}

2. **Text type**: the attribute is used for longer, variable-length character fields. (e.g. "The 4th experiment in the batch, it was sampled late, so may not be as accurate" ).

```
 ExtendedMetadataAttribute.new(title: 'description', required:true, sample_attribute_type: SampleAttributeType.where(title:'Text').first)
```
![](/images/user-guide/extended-metadata/attribute_text_type.png) 
{:.screenshot}

3. **Date type**: the attribute is used to represent dates. (e.g. January 1, 2015)
```
 ExtendedMetadataAttribute.new(title: 'study_start_date', required:true, sample_attribute_type: SampleAttributeType.where(title:'Date').first)
```
![](/images/user-guide/extended-metadata/attribute_date_type.png) 
{:.screenshot}

4. **Date-Time type**: the attribute is used to represent dates and times. (e.g. January 1, 2015 at 14:00 GMT)

```
 ExtendedMetadataAttribute.new(title: 'study_start_time', required:true, sample_attribute_type: SampleAttributeType.where(title:'Date time').first)
```
![](/images/user-guide/extended-metadata/attribute_time_type.png) 
{:.screenshot}

5. **Integer type**: the attribute is positive, negative, or zero numbers that do not have a fractional part. (e.g. 1, 2, 3, 4)

```
 ExtendedMetadataAttribute.new(title: 'study_age', required:true, sample_attribute_type: SampleAttributeType.where(title:'Integer').first)
```
![](/images/user-guide/extended-metadata/attribute_integer_type.png) 
{:.screenshot}

6. **Real Number**: the attribute is used to represent numbers that may have a fractional component or decimal point. (e.g. 180.5)

```
 ExtendedMetadataAttribute.new(title: 'cholesterol_level', required:true, sample_attribute_type: SampleAttributeType.where(title:'Real number').first)
```
![](/images/user-guide/extended-metadata/attribute_real_number_type.png) 
{:.screenshot}

7. **Boolean**: the attribute uses true and false to represent truth values. (e.g. true, false)

```
 ExtendedMetadataAttribute.new(title: 'resource_use_rights_authors_confirmation', required:true, sample_attribute_type: SampleAttributeType.where(title:'Boolean').first)
```
![](/images/user-guide/extended-metadata/attribute_boolean_type.png) 
{:.screenshot}

8. **Controlled Vocabulary**: The attribute is limited to a predefined set of terms, and users must choose from this set. This selection is presented as a single-select dropdown list in the user interface.

```
def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end


# Create a list of controlled vocablary for the personal title of role name

 role_name_personal_title_cv = SampleControlledVocab.where(title: 'Personal Title').first_or_create!(sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Mr.', 'Ms.', 'Dr.', 'Prof. Dr.', 'Other']))
 
 ExtendedMetadataAttribute.new(title: 'role_name_personal_title', required:true,
                                                                  sample_attribute_type: SampleAttributeType.where(title:'Controlled Vocabulary').first, sample_controlled_vocab: role_name_personal_title_cv)
    
```

![](/images/user-guide/extended-metadata/attribute_cv_type.png) 
{:.screenshot}

9. **Controlled Vocabulary List**: Unlike a single-select option in Controlled Vocabulary, Controlled Vocabulary List allows users to make multiple selections from a predefined set of terms for a given attribute. 

```
# Create a controlled vocabulary for European study countries.

    study_country_cv = SampleControlledVocab.where(title: 'study_country').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes([
      'Albania',
      'Austria',
      'Belgium',
      'Bosnia and Herzegovina',
      'Bulgaria',
      'Croatia',
      'Cyprus',
      'Czech Republic','Denmark',
      'Estonia',
      ....
    ]))

 ExtendedMetadataAttribute.new(title: 'study_country', required:true, sample_attribute_type: SampleAttributeType.where(title:'Controlled Vocabulary List').first, sample_controlled_vocab: study_country_cv)
```
![](/images/user-guide/extended-metadata/attribute_cvlist_type.png) 
{:.screenshot}

10. **Nested Extended Metadata**: the attribute allows for a hierarchical structure where one Extended Metadata type definition can reference another, resulting in the nesting of these types within a single form. 
Furthermore, The inner Extended Metadata type can also now be defined as a list, with the form allowing new items to be added or removed.

```
# Define the inner extended metadata type 'person' with attributes 'first_name' and 'last_name'.
# The 'supported_type' is set to 'ExtendedMetadata' to denote it as the inner extended metadata type.

unless ExtendedMetadataType.where(title: 'person', supported_type: 'ExtendedMetadata').any?

  emt = ExtendedMetadataType.new(title: 'person', supported_type: 'ExtendedMetadata')
  
  # Define 'first_name' attribute as a 'String' type 
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
    title: 'first_name',
    sample_attribute_type: SampleAttributeType.where(title: 'String').first
  )
  
  # Define 'last_name' attribute as a 'String' type
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
    title: 'last_name',
    sample_attribute_type: SampleAttributeType.where(title: 'String').first
  )
  emt.save!
end

# Define the extended metadata type 'family', which contains the nested extended metadata attributes 
person_emt = ExtendedMetadataType.where(title: 'person', supported_type: 'ExtendedMetadata').first

unless ExtendedMetadataType.where(title: 'family', supported_type: 'Investigation').any?
  emt = ExtendedMetadataType.new(title: 'family', supported_type: 'Investigation')
  
  # Define 'dad' attribute for 'family' linked to the 'person' type
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
    title: 'dad',
    sample_attribute_type: SampleAttributeType.where(title: 'Linked Extended Metadata').first,
    linked_extended_metadata_type: person_emt
  )
  
  # Define 'mom' attribute for 'family' linked to the 'person' type
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
    title: 'mom',
    sample_attribute_type: SampleAttributeType.where(title: 'Linked Extended Metadata').first,
    linked_extended_metadata_type: person_emt
  )

  # Define 'child' attribute for 'family' linked to the 'person' type (multiple children allowed)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
    title: 'child',
    sample_attribute_type: SampleAttributeType.where(title: 'Linked Extended Metadata (multiple)').first,
    linked_extended_metadata_type: person_emt
  )
end

```
![](/images/user-guide/extended-metadata/attribute_nested_type.png) 
{:.screenshot}

You can find the complete example [here](https://github.com/seek4science/seek/blob/main/db/seeds/extended_metadata_drafts/family_example.seeds.rb), you need to move the file under the `db/seeds` folder, then run the seed file using the command
```bundle exec rake db:seed:family_example``` from the SEEK instance root path.

### How to run the seed file?

[Here](https://github.com/seek4science/seek/blob/main/db/seeds/extended_metadata_drafts/extended_study_metadata_example.seeds.rb) is a seed file named **extended_study_metadata_example.seeds.rb**, which creates an Extended Metadata type named **"My study metadata"** for study. 

You can place it under the `db/seeds` folder, then run the seed file using the command
```bundle exec rake db:seed:extended_study_metadata_example``` from the SEEK instance root path.




