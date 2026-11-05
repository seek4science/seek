<a name="read"></a>A **Read** operation will return information about the instance identified, provided the authenticated user has access to it.

The **Read** operation returns a JSON object representing the instance.

For instances with a sharing policy, such as assets and ISA items, the `meta` block includes a `user_access` object, indicating whether the authenticated user (or an anonymous user, if not authenticated) is allowed to `view`, `download`, `edit`, `manage` and `delete` the instance. `download` is only included for instances that have something to download, such as assets with files; it is left out for ISA items, for example.

Success response codes:

* 200 OK

Error response codes:
* 403 Forbidden
* 404 Not found
