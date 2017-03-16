---
title: openSEEK
layout: page
---

# openSEEK

*openSEEK* is the name given to the combined package including both [SEEK](http://seek4science.org) and [openBIS](http://fairdom.eu/platform/openbis/)

The package is provided using Docker Compose, and became available with [SEEK version 1.3.0](/tech/releases/#version-130)


# Installation and running

First you should read the guide for [Docker](docker.html) and [Docker Compose](docker-compose.html)

Running openSEEK is essentially the same, but you will need to use a different compose file and create an additional volume

Create the additional volume for storing the openbis state with:

    docker volume create --name=openbis-state
    
The compose file to use is [docker-compose-openseek.yml](https://github.com/seek4science/seek/blob/master/docker-compose-openseek.yml)
  
When using Docker Compose you need to reference this compose file, for example:
  
    docker-compose -f docker-compose-openseek.yml up -d
    
and    

    docker-compose -f docker-compose-openseek.yml down

    