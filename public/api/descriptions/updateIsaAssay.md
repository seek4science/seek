<a name="updateIsaAssay"></a>An **updateIsaAssay** operation updates an existing <a href="#isaAssays">**ISA Assay**</a>, identified by its `id` (the Assay ID). The request body may include partial updates to the assay and/or its associated sample type.

All fields are optional — only the fields provided will be updated. ISA tag constraints are re-validated on save.

If sample attributes are renamed and samples already exist, a background job will update the stored sample metadata to reflect the new attribute titles.

The **updateIsaAssay** operation returns a JSON object containing the updated assay and its associated sample type.
