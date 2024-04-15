---
title: Docker - Docker compose
layout: page
---

# Docker

## Using docker compose

You can run SEEK in Docker together with MySQL and SOLR running in its own containers as micro-services, using Docker Compose.

You will first need [Docker installed](docker-install.html)

See the [Docker Compose Installation Guide](https://docs.docker.com/compose/install/) for how to install Docker Compose.

Once installed, all that is needed are the [docker-compose.yml](https://raw.githubusercontent.com/seek4science/seek/seek-{{ site.current_docker_tag }}/docker-compose.yml) and the [docker/db.env](https://raw.githubusercontent.com/seek4science/seek/seek-{{ site.current_docker_tag }}/docker/db.env) files,
although you can simply check out the SEEK source from GitHub - see [Getting SEEK](../install.html#getting-seek). You would be advised to change the passwords in the *db.env* file.

First you need to create 4 volumes

    docker volume create --name=seek-filestore
    docker volume create --name=seek-mysql-db
    docker volume create --name=seek-solr-data
    docker volume create --name=seek-cache

and then to start up, with the docker-compose.yml in your currently directory run

    docker compose up -d

and go to [http://localhost:3000](http://localhost:3000). There may be a short delay before you can connect, especially
if this is the first time and various things are being initialized.

to stop run

    docker compose down

You change the port, and image in the docker-compose.yml by editing

    seek:
        ..
        ..
        image: fairdom/seek:{{ site.current_docker_tag }}
        ..
        ..
        ports:
              - "3000:3000"

## Proxy through NGINX or Apache

An alternative to changing the port (particularly if running several instances on
same machine), you can proxy through Apache or Nginx. E.g. for Nginx you would configure a virtual host
like the following:

    server {
        listen 80;
        server_name www.my-seek.org;
        client_max_body_size 2G;

        location / {
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   Host      $host:$server_port;
            proxy_set_header   X-Forwarded-Proto $scheme;
            proxy_pass         http://127.0.0.1:3000;
        }
    }

for Apache the virtual host would include:

    UseCanonicalName on
    ProxyPreserveHost on
    <Location />
         ProxyPass   http://127.0.0.1:3000/ Keepalive=On
         ProxyPassReverse http://127.0.0.1:3000/
    </Location>

You would also want to configure for HTTPS (port 443), and would strongly recommend using [Lets Encrypt](https://letsencrypt.org/) for free SSL certificates.

## Backup and Restore

To backup the MySQL database and seek filestore, you will need to mount the volumes into a temporary container. Don't try backing up by copying the volumes directly from the host system.
The following gives an example of a basic procedure, but we recommend you read [Backup, restore, or migrate data volumes](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
 and are familiar with what the steps mean.

    docker compose stop
    docker run --rm --volumes-from seek -v $(pwd):/backup ubuntu tar cvf /backup/seek-filestore.tar /seek/filestore
    docker run --rm --volumes-from seek-mysql -v $(pwd):/backup ubuntu tar cvf /backup/seek-mysql-db.tar /var/lib/mysql
    docker compose start

and to restore into new volumes:

    docker compose down
    docker volume rm seek-filestore
    docker volume rm seek-mysql-db
    docker volume create --name=seek-filestore
    docker volume create --name=seek-mysql-db
    docker compose up --no-start
    docker run --rm --volumes-from seek -v $(pwd):/backup ubuntu bash -c "tar xfv /backup/seek-filestore.tar"
    docker run --rm --volumes-from seek-mysql -v $(pwd):/backup ubuntu bash -c "tar xfv /backup/seek-mysql-db.tar"
    docker compose up -d

**Note** that when rolling back a version, for example from an unsuccessful upgrade, it is particularly important to remove and recreate the *seek-filestore* and *seek-mysql-db* volumes - otherwise additional files may be left around when the backup is restored over the top.

The cache and solr index don't need backing up. Once up and running, if necessary the solr index can be regenerated with:

    docker exec seek bundle exec rake seek:reindex_all

## Upgrading between versions

The process is very similar to [Upgrading a Basic Container](basic-container.html#upgrades).

First update the [docker-compose.yml](https://github.com/seek4science/seek/blob/seek-{{ site.current_docker_tag }}/docker-compose.yml) for the new version.
You will be able to tell the version from the image tag - e.g for {{ site.current_docker_tag }}

    image: fairdom/seek:{{ site.current_docker_tag }}

using the new docker-compose.yml do:

    docker compose down
    docker compose pull
    docker compose up -d seek db solr            # avoiding the seek-workers, which will interfere
    docker exec -it seek docker/upgrade.sh
    docker compose down
    docker compose up -d


## Moving from a standalone installation to Docker Compose

If you have an existing SEEK installation running on "Bare Metal" and would like to move to using Docker compose, we have a script that can help migrate the data. The script was created to help move some of our own services, but hasn't been heavily tested beyond that so please use with care. Please feel free to [Contribute](/contributing-to-seek.html) any improvements.

First a dump of the mysql database is needed, which can be created using _mysqldump_

    mysqldump -u<user> -p <dbname> > seek.sql

Copy both _seek.sql_ and the _filestore/_ directory in to a separate directory, e.g:

    mkdir /tmp/seek-migration
    cp -rf filestore/ /tmp/seek-migration/
    cp seek.sql /tmp/seek-migration/

The script to use can be found at [https://github.com/seek4science/seek/blob/seek-{{ site.current_docker_tag }}/script/import-docker-data.sh](https://github.com/seek4science/seek/blob/seek-{{ site.current_docker_tag }}/script/import-docker-data.sh)

Start with a clean Docker Compose setup described above. Running the script, passing the location of the directory, will drop any existing volumes, recreate new ones and populate them with the sql and filestore data.

    wget https://github.com/seek4science/seek/raw/seek-{{ site.current_docker_tag }}/script/import-docker-data.sh
    sh ./import-docker-data.sh /tmp/seek-migration/

## Using a sub-URI

If you wish to run SEEK under a sub-URI (e.g. https://yourdomain.com/seek/) you can use the alternative `docker-compose-relative-root.yml` file:

    docker compose -f docker-compose-relative-root.yml up -d

To customize the sub-URI (`/seek` by default), change the `RAILS_RELATIVE_URL_ROOT` variable in that file in *both* the `seek` and `seek_workers` sections.

Please note if adding/changing/removing the `RAILS_RELATIVE_URL_ROOT` on an existing container, you will have to recompile assets and clear the cache:

    docker exec seek bundle exec rake assets:precompile
    docker exec seek bundle exec rake tmp:clear
