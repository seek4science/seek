---
title: SEEK User Guide - Managing Identities
layout: page
---

# Managing Identities

Depending on the configuration of the SEEK instance, in addition to the usual username/password method, 
you may be able to login through one of the following: 
 * LDAP
 * LS Login
 * GitHub
 * A custom OIDC provider
 
Each different way you login is considered an "identity", and you can potentially have multiple identities connected
to your SEEK account.

These can be managed on the "Manage Identities" page, which is found by clicking the user menu on the top-right.
Note: This link will not appear if there are no alternative login methods enabled on the SEEK instance.

![Manage Identities link](/images/user-guide/omniauth/manage_identities.png){:.screenshot}

<a name="add-identity"></a>
## Adding a new identity

If you already have a SEEK account and want to login using a different method, you can add a new identity by clicking the button on the top right:

![Add Identity button](/images/user-guide/omniauth/add_identity.png){:.screenshot}

(The options listed will vary depending on the SEEK configuration)

Clicking one of the identity options will direct you to login via that provider. 
For more detail on how to proceed with LS Login, see [here](aai.html#aai-flow).

After successfully logging in, you should be redirected back to the "Manage Identities" page, and see the new identity listed.

![New identity listed](/images/user-guide/omniauth/identity_added.png){:.screenshot}

## Removing an identity

If you no longer wish to use a certain identity to login with, you can unlink it from your account by clicking the "Unlink" button.
Before removing an identity, please ensure you have another method of logging into SEEK, or you may find yourself locked out of your account.
