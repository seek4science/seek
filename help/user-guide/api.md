---
title: API Introduction
layout: page
---

# API introduction

SEEK includes a [JSON](https://www.json.org/) Application
Programming Interface (API) that allows the **searching,
listing, reading, updating and creating** of many items in SEEK, 
along with their attributes.
  
Technical details about the JSON stuctures and available endpoints
 can be found in the [JSON API Overview](/tech/api/index.html); 
 and also on [SwaggerHub](https://app.swaggerhub.com/apis/FAIRDOM/SEEK/0.1) 
 where some aspects of the API can be tested out.

The API conforms to the [JSON API](http://jsonapi.org) specification which
describes a standard way of representing APIs in JSON.

# Authentication

Calls to the JSON API should use [Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
(base64 encoding of username and password). This
identifies the **“logged in”** user to SEEK. The API
only exposes those assets to which that user has access.
As a result, the results of a call will vary according
to which user is logged in.

The JSON API can also be used without any authentication,
in which case only publicly viewable information will
be returned.

<!--
# Excluded assets

The JSON API currently allows the searching, listing and
reading of all types of assets except
the reading of

* an individual Sample Type
* Samples
* Strains


# Future work

The SEEK team are currently working on extending the API
to include create, update and delete capabilities as well
as to cover currently excluded assets and attributes.
-->
