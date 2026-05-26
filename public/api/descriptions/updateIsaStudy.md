<a name="updateIsaStudy"></a>An **updateIsaStudy** operation updates an existing <a href="#isaStudies">**ISA Study**</a>, identified by its `id` (the Study ID). The request body may include partial updates to the study, source sample type, and/or sample collection sample type.

All fields are optional — only the fields provided will be updated. ISA tag constraints are re-validated on save:

* The source sample type must retain exactly one `source`-tagged attribute
* The sample collection sample type must retain exactly one `sample`-tagged and one `protocol`-tagged , and one `INPUT`-tagged attribute

If sample attributes are renamed and samples already exist, a background job will update the stored sample metadata to reflect the new attribute titles.

The **updateIsaStudy** operation returns a JSON object containing the updated study, source sample type, and sample collection sample type.
