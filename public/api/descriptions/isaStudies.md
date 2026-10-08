<a name="isaStudies"></a>An **ISA Study** is an ISA-compliant wrapper around a <a href="#studies">**Study**</a> that bundles the study with its two associated <a href="#sampleTypes">**Sample Types**</a>: the *source* sample type and the *sample collection* sample type. This structure enforces the ISA (Investigation–Study–Assay) framework for life science research.

An **ISA Study** bundles:

* A **Study** — with title, description, experimentalists, and a reference to its parent <a href="#investigations">**Investigation**</a>
* A **Source Sample Type** — defines the source material attributes. Must contain exactly one attribute with the `source` <a href="#ISA tags">**ISA Tag**</a> (is_title), and may contain additional attributes with the `source_characteristic` ISA tag
* A **Sample Collection Sample Type** — defines the collected sample attributes. Must contain exactly one attribute with the `sample` ISA tag (is_title), exactly one with the `protocol` ISA tag, and a SEEK Sample Multi attribute linking back to the source sample type

ISA tags can be retrieved from the <a href="#ISA tags">**ISA Tags**</a> endpoint (`/isa_tags`).

**ISA Studies** support <a href="#create">**Create**</a>, <a href="#update">**Update**</a>, and <a href="#read">**Read**</a> operations via the API. The read endpoint returns the study together with its sample types and the samples (visible to the authenticated user) within each sample type. To list studies, use the standard <a href="#studies">**Studies**</a> endpoints.
