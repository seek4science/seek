<a name="readGitBlob"></a>A **readGitBlob** operation will return a <a href="#gitBlob">Git blob (file)</a> at a given path under a resource (e.g. a workflow), provided the authenticated user has "download" rights.

The response includes some metadata about the blob (e.g. file size) as well as the base64-encoded file contents.
