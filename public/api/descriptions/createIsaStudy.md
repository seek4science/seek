<a name="createIsaStudy"></a>A **createIsaStudy** operation creates a new ISA-compliant <a href="#isaStudies">**ISA Study**</a>, consisting of a <a href="#studies">**Study**</a> and two linked <a href="#sampleTypes">**Sample Types**</a> (source and sample collection).

The request body must include:

* `study` — the study attributes, including `title` and `investigation_id`
* `source_sample_type` — the source sample type definition with `title` and `sample_attributes`. The source sample type must have:
  * Exactly one attribute with the `source` <a href="#ISA tags">**ISA Tag**</a> (set as `is_title: true`)
  * Any additional attributes with the `source_characteristic` ISA tag
* `sample_collection_sample_type` — the sample collection sample type definition with `title` and `sample_attributes`. The sample collection sample type must have:
  * Exactly one attribute with the `sample` ISA tag (set as `is_title: true`)
  * Exactly one attribute with the `protocol` ISA tag
  * Exactly one SEEK Sample Multi attribute (automatically links to the source sample type)

ISA tag IDs can be retrieved from the `/isa_tags` endpoint. Sample attribute type IDs can be retrieved from the `/sample_attribute_types` endpoint.

The **createIsaStudy** operation returns a JSON object containing the newly created study, source sample type, and sample collection sample type.
