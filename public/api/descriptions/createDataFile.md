<a name="createDataFile"></a>A **createDataFile** operation creates a new instance of a <a href="#dataFiles">**DataFile**</a>. The instance is populated with the content of the body of the API call.

Please note that when linking a data file to a workflow it currently isn't possible to define the relationship type (e.g test data, example data) through the api.

The **createDataFile** operation returns a JSON object representing the newly created <a href="#dataFiles">**DataFile**</a> and redirects to its URL.
