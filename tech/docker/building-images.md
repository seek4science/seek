---
title: Docker - Building your own images
layout: page
---

# Docker

## Building your own docker image

If you are doing your own development, or you want to tweak the Docker image, it is simple to build your own.

You need first of course, to have the SEEK code which you can get from [GitHub](https://github.com/seek4science/seek), see [Getting SEEK](../install.html#getting-seek)

The Docker image is determined by the [Dockerfile](https://github.com/seek4science/seek/blob/main/Dockerfile), 
and in most cases you shouldn't need to change this.

To build your own image, simply run the following from the root of the source folder

    docker build -t my-seek .
    
where _my-seek_ is the name of your image. Once it is built successfully, you can then run it, for example
    
    docker run -d -p 3000:3000 -v seek-filestore:/seek/filestore -v seek-db:/seek/sqlite3-db --name seek my-seek
    
If you are doing significant development on a Github fork of SEEK, 
you may want to look at [Automated builds with Docker Hub](https://docs.docker.com/docker-hub/builds/)  