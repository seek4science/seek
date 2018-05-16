---
title: openSEEK
layout: page
---

# openSEEK

*openSEEK* is the name given to the combined package including both [SEEK](http://seek4science.org) and [openBIS](http://fairdom.eu/platform/openbis/)

The package is provided using Docker Compose, and became available with [SEEK version 1.3.0](/tech/releases/#version-130)


## Installation and running

First you should read the guide for [Docker](docker.html) and in particular [Docker Compose](docker/docker-compose.html)

Running openSEEK is essentially the same, but you will need to use a different compose file and create an additional volume

Create the additional volume for storing the openbis state with:

    docker volume create --name=openbis-state
    
The compose file to use is [docker-compose-openseek.yml](https://github.com/seek4science/seek/blob/master/docker-compose-openseek.yml)
  
When using Docker Compose you need to reference this compose file, for example:
  
    docker-compose -f docker-compose-openseek.yml up -d
    
and    

    docker-compose -f docker-compose-openseek.yml down
    

You can reach SEEK through
    
[http://localhost:3000](http://localhost:3000)
    
after which you will need to create the initial account and profile. The SEEK will already be setup to talk to the openBIS.
    
You can reach openBIS through
    
[https://localhost:4000/openbis/](https://localhost:4000/openbis/)    
    
Note this uses a self-signed certificate by default. The default user is *admin* and password is *changeit*.    
    
    
            
## Standalone openBIS
    
You don't need to run the combined **openSEEK** package to use SEEK with openBIS. 

For SEEK versions following 1.6, you can use SEEK with a pre-existing openBIS which is running the 16.05.07 version. You can also install
openBIS separately using the [Standard openBIS installation](https://wiki-bsse.ethz.ch/display/bis/openBIS+Download+Page), or a single Docker container as follows:

    docker volume create name=openbis-state
    docker run -p 4000:443 -v openbis-state:/home/openbis/openbis_state openbis/debian-openbis:16.05.7

More details about running the openBIS Docker container can be found on [Docker Hub](https://hub.docker.com/r/openbis/debian-openbis/)
    
## Using SEEK and openBIS
    
For further instructions on how to use SEEK with openBIS please read our [User Guide](/help/user-guide/openbis.html)    