---
title: API Introduction
layout: page
---

# API introduction

SEEK includes a [JSON](https://www.json.org/) Application
Programming Interface (API) that allows the **searching,
listing, reading, updating and creating** of many items in SEEK, 
along with their attributes.

The API conforms to the [JSON API](http://jsonapi.org) specification which
describes a standard way of representing APIs in JSON.

Technical details about the JSON structures and available endpoints
 comes bundled with FAIRDOM-SEEK and can be found served from:

    http://<host>:<port>/api

For example, on the FAIRDOMHub it is [https://fairdomhub.org/api](https://fairdomhub.org/api), 
or for a local running instance it would be [http://localhost:3000/api](http://localhost:3000/api)

There are also some examples that are available as Jupyter notebook scripts. They were created for training events, and give
a general overview and walk through some typical scenarios. They can be found at [https://github.com/FAIRdom/api-workshop](https://github.com/FAIRdom/api-workshop
)

# Authentication

The API supports [Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication), OAuth and API Tokens.

More details can be found in [FAIRDOMHub API Docs](https://fairdomhub.org/api#section/Authentication)

The API can also be used without any authentication,
in which case only publicly viewable information will
be returned.
