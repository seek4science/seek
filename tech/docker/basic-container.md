---
title: Docker - Basic container
layout: page
---

# Docker

## Running a basic container

This is a single container is available for SEEK that runs on the SQLite3 database, which can only support a small number of concurrent users. 

**This isn't recommended for a production deployment**, but is a good quick way to try out SEEK, and for testing or checking out new features.
 
For production deployments see [Docker compose](docker-compose.html)

Once Docker is installed it can be started simply with:
 
    docker run -d -p 3000:3000 --name seek fairdom/seek:{{ site.current_docker_tag }}
    
This will start the container, and will be then available at [http://localhost:3000](http://localhost:3000) 
after a short few seconds wait for things to start up.
_( the container exposes port 3000 by default, if you want to map to a different port, e.g standard port 80, you can use -p 80:3000 )_     
    
If you wish to see the logs you can use
    
    docker logs seek
    
To stop the container you use
    
    docker stop seek
    
... and then to start again
    
    docker start seek
    
Once the container is finshed with, and after it has been stopped you can delete it with:
    
    docker rm seek
    
Note that in this simple form, deleting the container will also delete 
the data (see [Persistent Storage](#persistent-storage) for how to avoid this)    

### Image tags
   
The above example used the image name _fairdom/seek:{{ site.current_docker_tag }}_. The number following the : is the tag, and corresponds to the SEEK minor version _{{ site.current_docker_tag }}_ . 
From SEEK 1.1 onwards tags are available for each stable version of SEEK. 
Tags are available with or without the patch version - i.e _fairdom/seek:1.13.0_ and _fairdom/seek:1.13_. 
The image without the patch is always up to date with the latest version, whereas the image with the patch version is locked to that specific version and gives some more control over updates.

Our images are automatically built, and you can see the full list on the [FAIRDOM Docker Hub](https://hub.docker.com/r/fairdom/seek/tags/)
    
Note that there is also a _main_ tag. This is the latest development build of SEEK. 
It is useful for testing and trying out new cutting edge features, 
but is not suitable for a production deployment of SEEK.    

### Persistent Storage

If running a container for other than basic testing, you will want the stored data to be preserved when updating images. 
(However, if this is case you should be thinking about using [Docker compose](docker-compose.html)).

The recommended way to achieve persistance is to use named _data volumes_ for the database and filestore:
  
  
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:{{ site.current_docker_tag }}
    
this will create 2 volumes called _seek-filestore_ and _seek-db_, which you can see and manage with docker volumes, e.g
    
    docker volume ls
     
By using volumes the container can be thrown away and recreated (say, for a newer image) without losing your data.
    
For more detailed information about Volumes please read [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/)    


It is possible to do so by mounting a directory on the host machine for the database and filestore. E.g. to use /data/seek-filestore and /data/seek-db:

    docker run -d -p 3000:3000 -v /data/seek-filestore:/seek/filestore -v /data/seek-db:/seek/sqlite3-db --name seek fairdom/seek:{{ site.current_docker_tag }}


### Upgrades

Upgrades between SEEK container versions is only possible (and only makes sense) when [using Volumes](#persistent-storage). 
Also, upgrades are generally only necessary when switching between minor versions of SEEK. 

Switching to a newer build of the same version is as simple as:

    docker stop seek
    docker rm seek
    docker pull fairdom/seek:{{ site.current_docker_tag }}
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:{{ site.current_docker_tag }}
    
    
However, if moving between versions it is necessary to run some upgrade steps which can be achieved by usiung a temporary container.

If for example you have been running SEEK 1.1 with     

    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.1
    
and you now wish to upgrade to 1.2 then do:
    
    docker stop seek
    docker rm seek
    docker pull fairdom/seek:1.2
    docker run --rm -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db fairdom/seek:1.2 docker/upgrade.sh
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
        
You will now be running an upgraded SEEK 1.2
        
**IMPORTANT**: it is critical you only upgrade between successive versions, i.e. 1.1 -> 1.2 -> 1.3 and run the upgrade step at each stage. 
Jumping say, 1.1 -> 1.3 may introduce errors or missed steps during the upgrade.
