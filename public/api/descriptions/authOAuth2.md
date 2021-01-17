<a name="authentication"></a>
<a name="authentication-oauth"></a>If you are creating an application for others to use, the best solution is to register an
OAuth2 application in SEEK.

This can be done in SEEK by visiting *My Profile* > *Actions* > *API Applications*.

SEEK currently only supports the "Authorization Code" flow.

If your application runs client-side (such as in a web browser using JavaScript, or on a phone), you will need to make 
sure that the "Confidential?" checkbox is unticked, and you will need to implement the PKCE extention to the 
Authorization Code flow: https://oauth.net/2/pkce/
