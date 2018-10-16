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
    
You would also want to configure for HTTPS (port 443), and would strongly recommend using [Lets Encrypt](https://letsencrypt.org/) for free SSL certificates. 
    
## Backup and Restore

To backup the MySQL database and seek filestore, you will need to mount the volumes into a temporary container. Don't try backing up by copying the volumes directly from the host system. 
The following gives an example of a basic procedure, but we recommend you read [Backup, restore, or migrate data volumes](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
 and are familiar with what the steps mean.

    docker-compose stop
    docker run --rm --volumes-from seek -v $(pwd):/backup ubuntu tar cvf /backup/seek-filestore.tar /seek/filestore
    docker run --rm --volumes-from seek-mysql -v $(pwd):/backup ubuntu tar cvf /backup/seek-mysql-db.tar /var/lib/mysql
    docker-compose start -d
    
and to restore into new volumes:
        
    docker-compose down
    docker volume rm seek-filestore # this and the next step only necessary if you want to recreate existing volumes
    docker volume rm seek-mysql-db     
    docker volume create --name=seek-filestore
    docker volume create --name=seek-mysql-db
    docker-compose up --no-start
    docker run --rm --volumes-from seek -v $(pwd):/backup ubuntu bash -c "tar xfv /backup/seek-filestore.tar"
    docker run --rm --volumes-from seek-mysql -v $(pwd):/backup ubuntu bash -c "tar xfv /backup/seek-mysql-db.tar"
    docker-compose up -d        
    
Note that the cache and solr index don't need backing up. Once up and running, if necessary the solr index can be regenerated with:

    docker exec seek bundle exec rake reindex:all
        
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
 