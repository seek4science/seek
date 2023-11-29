---
title: "Setting up the Apache Solr Search Engine"
layout: page
---
# Setting up the Apache Solr Search Engine

Since version _1.12_ of FAIRDOM-SEEK [Apache Solr](https://solr.apache.org/) now needs to be setup separately rather than using the built in _Sunspot Solr_ .

This guide only relates to bare metal installations of FAIRDOM-SEEK. It doesn't affect using a 
[Docker](docker/docker-compose) based installation, where the changes are already handled for you.

There are two alternatives to installing and running Apache Solr. If possible, the simplest is to use our Docker
image. If this is not possible, there are also some instructions below on directly installing Apache Solr.

## Using the Docker Image

Using Docker provides the easiest solution to running Solr, pre-configured for SEEK, using the same _fairdom/seek-solr:8.11_
image that we use with Docker compose.

You first need to have [Docker installed](docker/docker-install). We provide example scripts for setting up and starting, as well as 
stopping the Solr service: 

  * [script/start-docker-solr.sh](https://github.com/seek4science/seek/blob/v{{ site.current_seek_version }}/script/start-docker-solr.sh)
    * When first executed this will fetch the image, and create a volume to persist the indexed data, and start the service. It is set to automatically restart
      unless explicitly stopped. On subsequent runs it will restart the service.
  * [script/stop-docker-solr.sh](https://github.com/seek4science/seek/blob/v{{ site.current_seek_version }}/script/stop-docker-solr.sh)
    * As is suggests, this will stop the service. The container and volume will remain, ready to be restarted.

These scripts should be run from the root directory of your SEEK installation, e.g:
    
    sh ./script/start-docker-solr.sh

The Docker container will be named _seek-solr_ and the volume named _seek-solr-data-volume_ .

Once running, and with search enabled, you can trigger jobs to reindex all searchable content with

    bundle exec rake seek:reindex_all

There is an additional script, [script/delete-docker-solr.sh](https://github.com/seek4science/seek/blob/v{{ site.current_seek_version }}/script/delete-docker-solr.sh), 
that can be used to delete both the container and volume.

## Installing Apache Solr

The following describes the steps for installing and setting up Solr on Ubuntu 20.04, but the process should be the same for
all Debian based distributions, and very similar for others. It is based on the guide found at [https://tecadmin.net/install-apache-solr-on-ubuntu-20-04/](https://tecadmin.net/install-apache-solr-on-ubuntu-20-04/) 
but the follwoing steps have been updated for solr 8.11.2.

First you should make sure Java 11 is installed. OpenJDK is fine

    sudo apt update
    sudo apt install openjdk-11-jdk

Double check this with

    java -version

If an different version is shown, use the following command and select the number for the correct version

    sudo update-alternatives --config java

The next step is to download and install Solr into _/opt/_, and set it up as a service

    cd /opt
    sudo wget https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz
    sudo tar xzf solr-8.11.2.tgz solr-8.11.2/bin/install_solr_service.sh --strip-components=2
    sudo bash ./install_solr_service.sh solr-8.11.2.tgz

The services can be stopped and started the usual way with

    sudo service solr stop
    sudo service solr start

You now need to set up the core configured for SEEK. Move to the root directory of the SEEK installation (in this example /srv/rails/seek)

    cd /srv/rails/seek
    sudo su - solr -c "/opt/solr/bin/solr create -c seek -d $(pwd)/solr/seek/conf"

The configuration and data for the SEEK core can be found in _/var/solr/data/seek_ .

You should be able to confirm the service is running and the core setup by visiting [http://localhost:8983/solr](http://localhost:8983/solr)

Solr is now setup, and you can trigger jobs to reindex the content with

    bundle exec rake seek:reindex_all






    



