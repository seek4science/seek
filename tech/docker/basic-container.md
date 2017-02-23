---
title: Docker - Basic container
layout: page
---

# Docker

## Running a basic container

A single container is available for SEEK that runs on the SQLite3 database, 
which is fine for a small to medium number of concurrent users. For larger deployments see [Docker compose](docker-compose.html)

This is a good way to try out your own local installation of SEEK. 

Once Docker is installed it can be started simply with:
 
    docker run -d -p 3000:3000 --name seek fairdom/seek:1.2
    
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
  
  
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
    
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
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek fairdom/seek:1.2
    docker exec seek bundle exec rake seek:reindex_all #(to rebuild the search index)
    
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
