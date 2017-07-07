---
title: Docker - Docker compose
layout: page
---

# Docker

## Using docker compose

You can run SEEK in Docker together with MySQL and SOLR running in its own containers as micro-services. 
To do this you use Docker Compose. 
See the [Docker Compose Installation Guide](https://docs.docker.com/compose/install/) for how to install.
 
Once installed, all that is needed is the [docker-compose.yml](https://github.com/seek4science/seek/blob/seek-{{ site.current_docker_tag }}/docker-compose.yml), and the [docker/db.env](https://github.com/seek4science/seek/blob/master/docker/db.env),
although you can simply check out the SEEK source from GitHub - see [Getting SEEK](../install.html#getting-seek).

First you need to create 4 volumes

    docker volume create --name=seek-filestore
    docker volume create --name=seek-mysql-db
    docker volume create --name=seek-solr-data
    docker volume create --name=seek-cache
    
and then to start up, with the docker-compose.yml in your currently directory run
    
    docker-compose up -d
    
and go to [http://localhost:3000](http://localhost:3000). There may be a short delay before you can connect, especially
if this is the first time and various things are being initialized.

to stop run
    
    docker-compose down
        
You change the port, and image in the docker-compose.yml by editing
    
    seek:
        ..
        ..
        image: fairdom/seek:{{ site.current_docker_tag }}
        ..
        ..
        ports:
              - "3000:3000"
              
## Proxy through NGINX              
              
An alternative to changing the port (particularly if running several instances on
same machine), you can proxy through Apache or Nginx. E.g. for Nginx you would configure a virtual host
like the following:

    server {
        listen 80; 
        server_name www.my-seek.org;
        client_max_body_size 2G;
        
        location / {
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   Host      $host;
            proxy_set_header   X-Forwarded-Proto $scheme;
            proxy_pass         http://127.0.0.1:3000;
        }
    }
    
## Upgrading between versions    

The process is very similar to [Upgrading a Basic Container](basic-container.html#upgrades).

First update the [docker-compose.yml](https://github.com/seek4science/seek/blob/seek-{{ site.current_docker_tag }}/docker-compose.yml) for the new version.
You will be able to tell the version from the image tag - e.g for {{ site.current_docker_tag }} 

    image: fairdom/seek:{{ site.current_docker_tag }}
    
using the new docker-compose.yml do:
    
    docker-compose down
    docker-compose pull
    docker-compose up -d seek db solr            # avoiding the seek-workers, which will interfere    
    docker exec -it seek docker/upgrade.sh
    docker-compose down
    docker-compose up -d
 