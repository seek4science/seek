---
title: assay types
layout: page
redirect_from: "/assay-types.html"
---

# Providing your own Assay and Technology types

This page describes how to customise the Assay and Technology types available in SEEK. The same approach is taken for
both assay and technology types.

## Ontology

The core types are described in an ontology as a class hierarchy, which by default is the ontology defined in _config/ontologies/JERM-RDFXML.owl_

**Note** that currently, the ontology first needs converting into RDFXML, which can be achieved using [Protégé](http://protege.stanford.edu/). The ontology we use is a RDFXML conversion
of our [JERM Ontology](https://www.jermontology.org)

By default both the Assay and Technology types are defined in the same ontology, but there is no reason why they could not be defined in separate ontologies if necessary.

There are 2 configurations that define the location of the ontology:

    Seek::Config.assay_type_ontology_file
    Seek::Config.technology_type_ontology_file

These can be defined in either the _config/initializers/seek_configuration.rb_
or directly manipulated using the [Rails console](http://guides.rubyonrails.org/command_line.html#rails-console).

The value can either be a URI, or a filename within the _config/ontologies/_ directory. If you wish to point to a file in a different directory use a file:// based URI.

On top of this you also need to configure the URI of the class in the ontology that defines the top level class for that type.
These settings are:

    Seek::Config.assay_type_base_uri
    Seek::Config.technology_type_base_uri


## Suggested types

As well the types defined by the ontology, a user may also suggest new types through the user interface. They will provide the term name,
 and suggest the possible parent term. These are stored in the database and linked to the assay.

Ideally, these suggested types will feed into the curation of the ontology, and if accepted will later be added to the ontology. During the curation, the parent term may end up
differing to that suggested by the user.

There is a rake task that will handle resynchronising with the ontology. Where a suggested type name matches a label in the appropriate ontology, the suggested type will be removed from
the database, and associated assays become linked with the ontology term URI instead.

This rake task is:

    rake seek:resynchronise_ontology_types