<a name="authentication-oidc-token"></a>If this instance is configured to sign in through an
OpenID Connect provider, and its administrator has enabled it, an access token issued by that
provider can be used directly as a credential for the API. No separate SEEK credential is
created, copied or stored, and the token expires on its own.

Place the token into the `Authorization` header when making API requests in the form:
`Bearer eyJhbGci...` where "eyJhbGci..." is the access token.

The token must come from *this* instance's configured provider, and the identity it belongs to
must already be linked to an account here. To link it, sign in to SEEK through the provider once
in a browser and complete your profile; no account is ever created by calling the API. Once
linked, the caller has exactly that user's own permissions.

*Note*: an instance may accept only tokens issued to particular applications, so a token that
works elsewhere may be refused here. Ask the administrator which applications are accepted.
