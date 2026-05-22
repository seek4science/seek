<a name="isaAssays"></a>An **ISA Assay** is an ISA-compliant wrapper around an <a href="#assays">**Assay**</a> that bundles it with an associated output <a href="#sampleTypes">**Sample Type**</a> and a reference to the input sample type from the preceding step in the assay stream.

An **ISA Assay** bundles:

* An **Assay** — with title, description, and references to its parent <a href="#studies">**Study**</a> and assay stream
* A **Sample Type** — defines the output material or data file attributes for this assay step. Must contain:
  * Exactly one attribute with the `protocol` <a href="#ISA tags">**ISA Tag**</a>
  * Exactly one SEEK Sample Multi attribute acting as the input link with an `input` ISA tag.
  * Exactly one attribute with either the `other_material` or `data_file` ISA tag (set as `is_title: true`)
  * Any additional attributes with characteristic or parameter value ISA tags
* An **input_sample_type_id** — the ID of the sample type from the preceding step (the study's sample collection sample type for the first assay, or the previous assay's sample type for subsequent assays)

ISA tags can be retrieved from the <a href="#ISA tags">**ISA Tags**</a> endpoint (`/isa_tags`).

**ISA Assays** support only <a href="#create">**Create**</a> and <a href="#update">**Update**</a> operations via the API. To read or list assays, use the standard <a href="#assays">**Assays**</a> endpoints.

Note: Assay streams (ISA assays with `assay_class_id` corresponding to the assay stream class) do not have an associated sample type.
