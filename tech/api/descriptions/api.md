The JSON API to FAIRDOM SEEK is a [JSON API](http://jsonapi.org)
specification describing how to read and write to a SEEK instance.

The API is defined in the [OpenAPI
specification](https://swagger.io/specification) currently in [version
2](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md)

Example IPython notebooks showing use of the API are available on [GitHub](https://github.com/seek4science/seekAPIexamples)

---

## Policy

A Policy specifies the visibility of an object to people using SEEK. A [**Project**](#tag/projects) may specify the default policy for objects belonging to that [**Project**](#tag/projects)

The **Policy** specifies the visibility of the object to non-registered people or [**People**](#tag/people) not allowed special access.

The access may be one of (in order of increasing "power"):

* no_access
* view
* download
* edit
* manage

In addition a **Policy** may give special access to specific [**People**](#tag/people), People working at an [**Institution**](#tag/institutions) or working on a [**Project**](#tag/projects).

---

## License

The license specifies the license that will apply to any [**DataFiles**](#tag/dataFiles), [**Models**](#tag/models), [**SOPs**](#tag/sops), [**Documents**](#tag/documents) and [**Presentations**](#tag/presentations) associated with a [**Project**](#tag/projects).

The license can currently be:

* [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/) - CC0 1.0
* [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/) - Creative Commons Attribution 4.0
* [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/) - Creative Commons Attribution Share-Alike 4.0
* [ODC-BY-1.0](http://www.opendefinition.org/licenses/odc-by) - Open Data Commons Attribution License 1.0
* [ODbL-1.0](http://www.opendefinition.org/licenses/odc-odbl) - Open Data Commons Open Database License 1.0
* [ODC-PDDL-1.0](http://www.opendefinition.org/licenses/odc-pddl) - Open Data Commons Public Domain Dedication and Licence 1.0
* notspecified - License Not Specified
* other-at - Other (Attribution)
* other-open - Other (Open)
* other-pd - Other (Public Domain)
* [AFL-3.0](http://www.opensource.org/licenses/AFL-3.0) - Academic Free License 3.0
* [Against-DRM](http://www.opendefinition.org/licenses/against-drm) - Against DRM
* [CC-BY-NC-4.0](https://creativecommons.org/licenses/by-nc/4.0/) - Creative Commons Attribution-NonCommercial 4.0
* [DSL](http://www.opendefinition.org/licenses/dsl) - Design Science License
* [FAL-1.3](http://www.opendefinition.org/licenses/fal) - Free Art License 1.3
* [GFDL-1.3-no-cover-texts-no-invariant-sections](http://www.opendefinition.org/licenses/gfdl) - GNU Free Documentation License 1.3 with no cover texts and no invariant sections
* [geogratis](http://geogratis.gc.ca/geogratis/licenceGG) - Geogratis
* [hesa-withrights](http://www.hesa.ac.uk/index.php?option=com_content&amp;task=view&amp;id=2619&amp;Itemid=209) - Higher Education Statistics Agency Copyright with data.gov.uk rights
* localauth-withrights - Local Authority Copyright with data.gov.uk rights
* [MirOS](http://www.opensource.org/licenses/MirOS) - MirOS Licence
* [NPOSL-3.0](http://www.opensource.org/licenses/NPOSL-3.0) - Non-Profit Open Software License 3.0
* [OGL-UK-1.0](http://reference.data.gov.uk/id/open-government-licence) - Open Government Licence 1.0 (United Kingdom)
* [OGL-UK-2.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/2/) - Open Government Licence 2.0 (United Kingdom)
* [OGL-UK-3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) - Open Government Licence 3.0 (United Kingdom)
* [OGL-Canada-2.0](http://data.gc.ca/eng/open-government-licence-canada) - Open Government License 2.0 (Canada)
* [OSL-3.0](http://www.opensource.org/licenses/OSL-3.0) - Open Software License 3.0
* [dli-model-use](http://data.library.ubc.ca/datalib/geographic/DMTI/license.html) - Statistics Canada: Data Liberation Initiative (DLI) - Model Data Use Licence
* [Talis](http://www.opendefinition.org/licenses/tcl) - Talis Community License
* ukclickusepsi - UK Click Use PSI
* ukcrown-withrights - UK Crown Copyright with data.gov.uk rights
* [ukpsi](http://www.opendefinition.org/licenses/ukpsi) - UK PSI Public Sector Information

---

## ContentBlob

The content of a [**DataFile**](#tag/dataFiles), [**Document**](#tag/documents), [**Model**](#tag/models), [**SOP**](#tag/sops) or [**Presentation**](#tag/presentations) is specified as a set of **ContentBlobs**.

When a resource with content is created, it is possible to specify a ContentBlob either as:

* A remote ContentBlob with:
  * **URI to the content's location**
  * The original filename for the content
  * The content type of the remote content as a [MIME media type](https://en.wikipedia.org/wiki/Media_type)
* A placeholder that will be filled with uploaded content
  * **The original filename for the content**
  * **The content type of the content as a [MIME media type](https://en.wikipedia.org/wiki/Media_type)**

The creation of the resource will return a JSON document containing ContentBlobs corresponding to the remote ContentBlob and to the ContentBlob placeholder. The blobs contain a URI to their location.

A placeholder can then be satisfied by uploading a file to the location URI. For example by a placeholder such as 

```
"content_blobs": [
  {
    "original_filename": "a_pdf_file.pdf",
    "content_type": "application/pdf",
    "link": "http://www.fairdomhub.org/data_files/57/content_blobs/313"
  }
],
```

may be satisfied by uploading a file to http://www.fairdomhub.org/data_files/57/content_blobs/313 using the [uploadDataFileContent](#operation/uploadDataFileContent) operation

The content of a resource may be downloaded by first *reading* the resource and then *downloading* the ContentBlobs from their URI.

---