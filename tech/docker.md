---
title: Docker
layout: page
---

# Docker

## Introduction to Docker

Docker is a toolset for running applications in isolated containers. They
are similar to virtual machines, but run on the same hardware and kernel as the
host system. Docker can be used to create and run images which are a complete
package of the application and its system and runtime dependencies.

For more information please visit the [Docker website](https://www.docker.com/)

## Installing Docker

As a miminum you will need the Docker Engine. For details on how to install
on a number of platforms please read the [Docker Engine Install Guides](https://docs.docker.com/engine/installation/)

Optionally, for larger deployments you will also need [Docker Compose](https://docs.docker.com/compose/), 
which also provides and [Installation Guide](https://docs.docker.com/compose/install/)


## Running a basic container

A single container is available for SEEK that runs on the SQLite3 database, which is fine for a small number of concurrent users.

This is a good way to try out your own local installation of SEEK. Once Docker is installed it can be started simply with:
 
    docker run -d -p 8080:80 --name seek fairdom/seek:1.2
    
This will start the container, and will be then available on http://localhost:8080 after a short wait for things to start up.
_( -p 8080:80 maps port 8080 to the standard http port 80, if you wish to use port 80 then you can omit this, or use another port such as -p 3000:80 )_     
    
If you wish to see the logs you can use
    
    docker logs seek
    
To stop the container you use
    
    docker stop seek
    
... and then to start again
    
    docker start seek
    
Once the container is finshed with, and after it has been stopped you can delete it with:
    
    docker rm seek
    
Note that in this simple form, this will also delete the data (see [Using volumes](#using-volumes) for how to avoid this)    
   
### Image tags
   
The above example used the image name _fairdom/seek:1.2_. The number following the : is the tag, and corresponds to the SEEK minor version _1.2_ . From SEEK 1.1 onwards tags are available for each
stable version of SEEK. Note that the patch version (i.e. the x in 1.1.x is omitted, the image is always up to date with the latest patch and fixes).

Our images are automatically build, and you can see the full list on the [FAIRDOM Docker Hub](https://hub.docker.com/r/fairdom/seek/tags/)
    
Note that there is also a _master_ tag. This is the latest development build of SEEK. It is useful for testing and trying out new cutting edge features, but is not suitable for a production deployment of SEEK.    

### Using volumes

If you are using Docker for a deployment for real use, rather than just testing or trying out, then you will want your data and files to be preserved. Using the previous examples this would be inside the container
and lost once the container is deleted. You can avoid this by telling the container to use a couple of Docker volumes for the database and filestore.
  
  
    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
    
this will create 2 volumes called _seek-filestore_ and _seek-db_, which you can see and manage with docker volumes, e.g
    
    docker volume ls
    
For backing up, Docker volumes are stored at _/var/lib/docker/volumes_ (sudo required). By using volumes the container can be thrown away and recreated (say for a newer image) without losing your data.    

### Upgrades

## Using docker compose

## Building your own docker image