<a name="createIsaAssay"></a>A **createIsaAssay** operation creates a new ISA-compliant <a href="#isaAssays">**ISA Assay**</a>, consisting of an <a href="#assays">**Assay**</a> and an associated output <a href="#sampleTypes">**Sample Type**</a>.

The request body must include:

* `assay` — the assay attributes, including:
  * `title` — the assay title
  * `study_id` — the ID of the parent study
  * `assay_class_id` — the ID of the assay class (use the experimental assay class for standard assays)
  * `assay_stream_id` — the ID of the parent assay stream (for experimental assays)
* `sample_type` — the output sample type definition with `title` and `sample_attributes`. Required unless creating an assay stream. Must contain:
  * Exactly one attribute with the `protocol` <a href="#ISA tags">**ISA Tag**</a>
  * Exactly one input attribute of type `SEEK Sample Multi` with the `input` ISA tag, linking to the previous sample type
  * Exactly one attribute with either `other_material` or `data_file` ISA tag (set as `is_title: true`)
* `input_sample_type_id` — the ID of the sample type from the previous step in the assay stream. For the first assay in a stream, this is the study's sample collection sample type ID.

ISA tag IDs can be retrieved from the `/isa_tags` endpoint. Sample attribute type IDs can be retrieved from the `/sample_attribute_types` endpoint.

The **createIsaAssay** operation returns a JSON object containing the newly created assay and its associated sample type.
