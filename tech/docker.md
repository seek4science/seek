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

As a miminum you will need the Docker Engine. 

For details on how to install on a number of platforms please read 
the [Docker Engine Install Guides](https://docs.docker.com/engine/installation/)

Optionally, for larger deployments you will also need [Docker Compose](https://docs.docker.com/compose/), 
which also provides an [Installation Guide](https://docs.docker.com/compose/install/)


## Running a basic container

A single container is available for SEEK that runs on the SQLite3 database, 
which is fine for a small to medium number of concurrent users. For larger deployments see [Docker compose](#using-docker-compose)

This is a good way to try out your own local installation of SEEK. 

Once Docker is installed it can be started simply with:
 
    docker run -d -p 80:80 --name seek fairdom/seek:1.2
    
This will start the container, and will be then available at [http://localhost:8080](http://localhost:8080) 
after a short few seconds wait for things to start up.
_( -p 8080:80 maps port 8080 to the standard http port 80, if you wish
 to use port 80 then use -p 80:80, or use another port such as -p 3000:80 )_     
    
If you wish to see the logs you can use
    
    docker logs seek
    
To stop the container you use
    
    docker stop seek
    
... and then to start again
    
    docker start seek
    
Once the container is finshed with, and after it has been stopped you can delete it with:
    
    docker rm seek
    
Note that in this simple form, deleting the container will also delete 
the data (see [Using volumes](#using-volumes) for how to avoid this)    
   
### Image tags
   
The above example used the image name _fairdom/seek:1.2_. The number following the : is the tag, and corresponds to the SEEK minor version _1.2_ . 
From SEEK 1.1 onwards tags are available for each stable version of SEEK. 
Note that the patch version (i.e. the x in 1.1.x is omitted, the image is always up to date with the latest patch and fixes).

Our images are automatically built, and you can see the full list on the [FAIRDOM Docker Hub](https://hub.docker.com/r/fairdom/seek/tags/)
    
Note that there is also a _master_ tag. This is the latest development build of SEEK. 
It is useful for testing and trying out new cutting edge features, 
but is not suitable for a production deployment of SEEK.    

### Using volumes

If you are using Docker for a SEEK deployment for real use, rather than just testing or trying out, 
then you will want your data and files to be preserved. 
Using the previous examples they would be inside the container
and lost once the container is deleted. 
You can avoid this by telling the container to use a couple of Docker volumes for the database and filestore.
  
  
    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
    
this will create 2 volumes called _seek-filestore_ and _seek-db_, which you can see and manage with docker volumes, e.g
    
    docker volume ls
    
For backing up purposes, Docker volumes are stored at _/var/lib/docker/volumes_ (sudo required). 
By using volumes the container can be thrown away and recreated (say, for a newer image) without losing your data.
    
For more detailed information about Volumes please read [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/)    

### Upgrades

Upgrades between SEEK container versions is only possible (and only makes sense) when [using Volumes](#using-volumes). 
Also, upgrades are generally only necessary when switching between minor versions of SEEK. 

Switching to a newer build of the same version is as simple as:

    docker stop seek
    docker rm seek
    docker pull fairdom/seek:1.2
    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
    docker exec seek bundle exec seek:reindex_all #(to rebuild the search index)
    
However, if moving between versions it is necessary to run some upgrade steps which can be achieved by usiung a temporary container.

If for example you have been running SEEK 1.1 with     

    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.1
    
and you now wish to upgrade to 1.2 then do:
    
    docker stop seek
    docker rm seek
    docker pull fairdom/seek:1.2
    docker run --rm -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db fairdom/seek:1.2 docker/upgrade.sh
    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
        
You will now be running an upgraded SEEK 1.2
        
**IMPORTANT**: it is critical you only upgrade between successive versions, i.e. 1.1 -> 1.2 -> 1.3 and run the upgrade step at each stage. 
Jumping say, 1.1 -> 1.3 may introduce errors or missed steps during the upgrade.       


## Using docker compose

If necessary, you can run SEEK in Docker together with MySQL and SOLR running in its own containers. 
To do this you use Docker Compose. 
See the [Installation Guide](https://docs.docker.com/compose/install/) for how to install.
 
Once installed, all you need is the [docker-compose.yml](https://github.com/seek4science/seek/blob/master/docker-compose.yml), and the [docker/db.env](https://github.com/seek4science/seek/blob/master/docker/db.env),
although you can simply check out the SEEK source from GitHub.

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
    

## Building your own docker image

If you are doing your own development, or you want to tweak the Docker image, it is simple to build your own.

You need first of course, to have the SEEK code which you can get from [GitHub](https://github.com/seek4science/seek), see [Installing SEEK](install.html#getting-seek)

The Docker image is determined by the [Dockerfile](https://github.com/seek4science/seek/blob/master/Dockerfile), 
and in most cases you shouldn't need to change this.

To build your own image, simply run the following from the root of the source folder

    docker build -t my-seek .
    
where my-seek is the name of your image. Once it is built successfully, you can then run it, for example
    
    docker run -d -p 8080:80 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek my-seek
    
If you are doing significant development on a Github fork of SEEK, 
you may want to look at [Automated builds with Docker Hub](https://docs.docker.com/docker-hub/builds/)    