---
title: SEEK User Guide - Logging in via LS Login
layout: page
---

# Logging into SEEK via LS Login

*Note*: This section assumes you have an LS Login account (or your organization is connected to LS Login), 
and LS Login authentication is enabled on the SEEK instance you are using. For more information on LS Login, please 
see their [documentation](https://lifescience-ri.eu/ls-login/documentation/user-documentation/user-documentation.html){:target="_blank"}.

Already got a SEEK account? See how to [add LS Login to your account](managing-identities.html#add-identity) instead. 

If enabled on the SEEK instance you are using, you will see a tab on the login form titled "LS Login"

Clicking this will switch to the LS Login tab and present the LS Login login button.

![LS Login tab selected](/images/user-guide/omniauth/ls_login_button.png){:.screenshot}

<a name="aai-flow"></a>
Clicking this button will redirect your browser to LS Login, 
where you will be asked to choose your "Identity Provider", which will usually be your academic institution.
If you have logged in using LS Login before, your institution may be highlighted at the top, 
otherwise you can use the search box to find it.

![LS Login identity provider selection](/images/user-guide/omniauth/ls_login_inst_choice.png){:.screenshot}

You will then be redirected to your institution's login page, where you can login using your institution account's credentials. 
Note: this will likely look different to the screenshot below.

![Institution login form](/images/user-guide/omniauth/inst_login.png){:.screenshot}

After logging in through your institution, you may then be presented with a personal information consent page, 
which outlines what personal data will be provided by LS Login to the SEEK instance.

At a minimum, the identifier must be provided, or login is not possible. Any other information is used solely to 
populate fields in your SEEK profile.

If this is your first time logging in via LS Login, you will be directed to create a new "Profile". For guidance on how to do this, see [Registering in SEEK](registering.html#new-profile). Some fields such as your name and email address may already be populated with information provided by your institution.

Otherwise, you will be directed to the home page and should now be logged in.
