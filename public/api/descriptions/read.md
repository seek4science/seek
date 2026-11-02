<a name="read"></a>A **Read** operation will return information about the instance identified, provided the authenticated user has access to it.

The **Read** operation returns a JSON object representing the instance.

The `meta` block of the instance includes a `can` object, indicating whether the authenticated user (or an anonymous user, if not authenticated) is allowed to `view`, `download`, `edit`, `manage` and `delete` the instance.

Success response codes:

* 200 OK

Error response codes:
* 403 Forbidden
* 404 Not found
