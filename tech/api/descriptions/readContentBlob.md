<a name="readContentBlob"></a>A **readContentBlob** operation will return information about the <a href="#contentBlobs">ContentBlob</a> identified, provided the authenticated user has access to it.

The **readContentBlob** operation may return
* a JSON object representing the <a href="#contentBlobs">**ContentBlob**</a>.
* a csv file, if **text/csv** is specified in the **Accept** header and if the content blob can be converted into a csv or is already a csv
