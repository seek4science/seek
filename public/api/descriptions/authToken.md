<a name="authentication-token"></a>If you are creating a simple script that makes use of the SEEK API, where implementing
OAuth2 is unnecessarily complicated, you can create an API Token.

This can be done in SEEK by visiting *My Profile* > *Actions* > *API Tokens*.

*Note*: You will only be shown your API Token once, so make sure to paste it somewhere.

To use your API Token, place it into the `Authorization` header when making API requests in the form: `Token abce1234...`
where "abce1234..." is your token.

*Warning*: API Tokens grant access to your account! Do not share them with anyone. You can revoke API Tokens at any time.
