---
title: SEEK User Guide - Logging in via ELIXIR AAI
layout: page
---

# Logging into SEEK via ELIXIR AAI

*Note*: This section assumes you have an ELIXIR AAI account (or your organization is connected to ELIXIR AAI), 
and ELIXIR AAI authentication is enabled on the SEEK instance you are using. For more information on ELIXIR AAI, please 
see their [documentation](https://elixir-europe.org/services/compute/aai-documentation){:target="_blank"}.

Already got a SEEK account? See how to [add ELIXIR AAI to your account](managing-identites.html#add-identity) instead. 

If enabled on the SEEK instance you are using, you will see a tab on the login form titled "ELIXIR AAI"

![Login form](/images/user-guide/omniauth/aai_tab.png){:.screenshot}

Clicking this will switch to the ELIXIR AAI tab and present the ELIXIR AAI login button.

![ELIXIR AAI tab selected](/images/user-guide/omniauth/aai_button.png){:.screenshot}

<a name="aai-flow"></a>
Clicking this button will redirect your browser to ELIXIR AAI, 
where you will be asked to choose your "Identity Provider", which will usually be your academic institution.
If you have logged in using ELIXIR AAI before, your institution may be highlighted at the top, 
otherwise you can use the search box to find it.

![ELIXIR AAI identity provider selection](/images/user-guide/omniauth/aai_inst_choice.png){:.screenshot}

You will then be redirected to your institution's login page, where you can login using your institution account's credentials. 
Note: this will likely look different to the screenshot below.

![Institution login form](/images/user-guide/omniauth/inst_login.png){:.screenshot}

After logging in through your institution, you may then be presented with a personal information consent page, 
which outlines what personal data will be provided by ELIXIR AAI to the SEEK instance:

![ELIXIR AAI personal information consent page](/images/user-guide/omniauth/identity_consent.png){:.screenshot}

At a minimum, the identifier must be provided, or login is not possible. Any other information is used solely to 
populate fields in your SEEK profile.

If this is your first time logging in via ELIXIR AAI, you will be directed to create a new "Profile". For guidance on how to do this, see [Registering in SEEK](registering.html#new-profile). Some fields such as your name and email address may already be populated with information provided by your institution.

Otherwise, you will be directed to the home page and should now be logged in.
