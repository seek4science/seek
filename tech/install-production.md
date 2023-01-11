---
title: installing for production
layout: page
redirect_from: "/install-production.html"
---

# Installing SEEK in a production environment

This page contains some extra notes about setting up SEEK for production (i.e.
for real use rather than for development).

By reading and following these extra notes, you will more performance out of
SEEK, and reduce the ongoing maintenance.

If you wish to run under a sub URI, e.g. example.com/seek, then please read and
follow [Installing under a sub URI](install-on-suburi.html) at the end
of the installation.

## Before you install SEEK

This will make sure some of the rake tasks affect the appropriate database.

To save time later there are also some additional packages to install:

    sudo apt-get install libapr1-dev libaprutil1-dev

First create a user to own the SEEK application:

    sudo useradd -m seek

We recommend installing SEEK in /srv/rails/seek - first you need to create
this and grant permissions to `seek`

    sudo mkdir -p /srv/rails
    sudo chown seek:seek /srv/rails

Now switch to the `seek` user

    sudo su - seek
    cd /srv/rails

Before following the standard INSTALL guide you need to set an environment
variable to indicate that you intend to setup and run SEEK as production.

    export RAILS_ENV=production

you will need to reset this variable if you close your shell and start a new
session


You can now follow the overall [Installation Guide](install.html), and
then return to this page for some additional steps to get SEEK running
together with Apache, and also automating the required services.

If you have problems with requiring a sudo password during the RVM steps -
first setup RVM and ruby-1.9.3 as a user with sudo access, and repeat the
steps as the `seek` user. This means the required packages should then be
installed. At the time of writing this guide this shouldn't be necessary.

## Bundler Configuration

When installing gems with Bundler, first configure with

    bundle config set deployment 'true'
    bundle config set without 'development test'

this will prevent gems being accidentally changed, and also avoid unnecessary gems being installed.

## After you have installed SEEK

## Compiling Assets

Assets - such as images, javascript and stylesheets, need to be precompiled -
which means minifying them, grouping some together into a single file, and
compressing. These then get placed into *public/assets*. To compile them run
the following command. This can take some time, so be patient

    bundle exec rake assets:precompile

### Serving SEEK through Apache

First you need to setup [Passenger Phusion](https://www.phusionpassenger.com/library/install/apache/install/oss/bionic/).

#### Install Passenger

The following steps are taken from the above guide:

Install PGP key:

    sudo apt-get install -y dirmngr gnupg
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates

Add apt repository:

    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update

Install Apache module:

    sudo apt-get install -y libapache2-mod-passenger

Enable the module:

    sudo a2enmod passenger
    sudo apache2ctl restart

Check everything worked:

    sudo /usr/bin/passenger-config validate-install

#### Apache configuration

Now create a virtual host definition for SEEK:

    sudo nano /etc/apache2/sites-available/seek.conf

which looks like (if you have registered a DNS for your site, then set
ServerName appropriately):

    <VirtualHost *:80>
      ServerName www.yourhost.com

      PassengerRuby /usr/local/rvm/rubies/seek/bin/ruby

      DocumentRoot /srv/rails/seek/public
       <Directory /srv/rails/seek/public>
          # This relaxes Apache security settings.
          Allow from all
          # MultiViews must be turned off.
          Options -MultiViews
          Require all granted
       </Directory>
       <LocationMatch "^/assets/.*$">
          Header unset ETag
          FileETag None
          # RFC says only cache for 1 year
          ExpiresActive On
          ExpiresDefault "access plus 1 year"
       </LocationMatch>
    </VirtualHost>

(Notice we are referencing our "seek" alias in the `PassengerRuby` directive.)

The LocationMatch block tells Apache to serve up the assets (images, CSS,
Javascript) with a long expiry time, leading to better performance since these
items will be cached. You may need to enable the *headers* and *expires*
modules for Apache, so run:

    sudo a2enmod headers
    sudo a2enmod expires

Now enable the SEEK site, and disable the default that is installed with
Apache, and restart:

    sudo a2ensite seek
    sudo a2dissite 000-default
    sudo service apache2 restart

If you now visit http://localhost (note there is no 3000 port) - you should
see SEEK.

If you wish to restart SEEK, maybe after an upgrade, without restarting Apache
you can do so by running (as the `seek` user)

    touch /srv/rails/seek/tmp/restart.txt
    
### Configuring for HTTPS

We would strongly recommend using [Lets Encrypt](https://letsencrypt.org/) for free SSL certificates.     

### Setting up the services

The following steps show how to setup delayed_job and
soffice to run as a service, and automatically start and shutdown when you
restart the server. Apache Solr should already be setup from following the [Setting up Solr](setting-up-solr) instructions.


#### Delayed Job Background Service

Create the file /etc/init.d/delayed_job-seek and copy the contents of
[scripts/delayed_job-seek](scripts/delayed_job-seek) into it.

The run:

    sudo chmod +x /etc/init.d/delayed_job-seek
    sudo update-rc.d delayed_job-seek defaults

start it up with:

    sudo /etc/init.d/delayed_job-seek start

