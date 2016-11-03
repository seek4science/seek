---
title: Docker - Docker compose
layout: page
---

# Docker

## Using docker compose

If necessary, you can run SEEK in Docker together with MySQL and SOLR running in its own containers. 
To do this you use Docker Compose. 
See the [Installation Guide](https://docs.docker.com/compose/install/) for how to install.
 
Once installed, all you need is the [docker-compose.yml](https://github.com/seek4science/seek/blob/master/docker-compose.yml), and the [docker/db.env](https://github.com/seek4science/seek/blob/master/docker/db.env),
although you can simply check out the SEEK source from GitHub - see [Getting SEEK](../install.html#getting-seek).

First you need to create 3 volumes

    docker volume create --name=seek-filestore
    docker volume create --name=seek-mysql-db
    docker volume create --name=seek-solr-data
    
and then to start up, with the docker-compose.yml in your currently directory run
    
    docker-compose -d up
    
and go to http://localhost:8080

to stop run
    
    docker-compose down
        
You change the port, and image in the docker-compose.yml by editing
    
    seek:
        ..
        ..
        image: fairdom/seek:1.2
        ..
        ..
        ports:
              - "8080:80"