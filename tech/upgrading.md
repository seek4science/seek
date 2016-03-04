---
title: upgrading seek
layout: page
redirect_from: "/upgrading.html"
---

# Upgrading SEEK

If you have an existing SEEK installation, and you haven't done so already,
please take a moment to fill out our very short,optional [SEEK Registration
Form](http://www.sysmo-db.org/seek-registration). Doing so will be very useful
to us in the future when we try and raise further funding to develop and
support SEEK and the associated tools.

**Always backup your SEEK data before starting to upgrade!!** - see the
[Backup Guide](backups.html).

This guide assumes that SEEK has been installed following the [Installation
Guide](install.html) guide. It assumes it is a production server that is
being updated, and that commands are run from the root directory of the SEEK
application.

If your current installation is not linked to to the SEEK BitBucket Mercurial
repository, it can still easily be updated by taking the next stable tag,
reconfiguring the database configuration to point at your existing database,
and copying across the *filestore/* directory. The upgrade steps can then be
followed, with the Mercurial (hg) steps omitted.

## Identifying your version

The version of SEEK you are running is shown at the bottom left, within the
footer, when viewing pages in SEEK.

You can also tell which version you have installed by looking at the
*config/version.yml* file, so for example version 0.13.2 looks something like:

    major: 0
    minor: 13
    patch: 2

## General notes about versions and upgrading



**When upgrading between minor versions (i.e. from 0.11.x to 0.13.x)** it is
necessary to run a seek:upgrade rake task to perform upgrade changes and
import any new data. The upgrade task may require an internet connection, and
sometimes can take some time to run, so please be patient. There are
instructions for upgrading between each minor version listed below, but they
will generally follow the same pattern. Upgrading to version 0.18 is an
exception and involves some additional steps - due to the upgrade of the
required versions of Rails and Ruby.

**When upgrading between patch versions (i.e between 0.16.0 and 0.16.3)** it
should only be necessary to run *bundle install* and the *db:migrate* rake
task. Using seek:upgrade should still work, but could take a lot of
unnecessary time. There is more details and an example towards the end of the
this page.


## Steps to upgrade from 0.23.x to 1.0.x

### Dependencies
libgmp-dev is needed for RedCloth with ruby 2.1.7

    sudo apt-get install libgmp-dev

### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Update Ruby with RVM

Although not critical, we recommend updating Ruby to 2.1.7. If you are using
RVM, as recommended in the installation, you can do this with:

    rvm get stable
    rvm upgrade 2.1.6 2.1.7

The above upgrade command will copy across all previous gemsets (see:[https://rvm.io/rubies/upgrading](https://rvm.io/rubies/upgrading)).
If you have gemsets for other applications and copying them all isn't desirable, then you may want to start afresh:

    rvm install ruby-2.1.7

### Make sure bundler is installed

    gem install bundler

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v1.0.2

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
<https://bitbucket.org/seek4science/seek/downloads/seek-1.0.2.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.0.2.tar.gz

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is *config/database.yml*,
and the filestore is simply *filestore/*

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd .. && cd seek #this is to allow RVM to pick up the ruby and gemset changes
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while

### Restarting services

    bundle exec rake seek:workers:start
    bundle exec rake sunspot:solr:start
    touch tmp/restart.txt
    bundle exec rake tmp:clear

## Extra steps for a production server

If the upgrade has involved an upgrade of Ruby, and you are running a production service with Apache and Passenger Phusion, you will need
 to update the Apache config. You will need to point to the correct ruby wrapper script according to your version. The full path may differ, but for example

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.6/wrappers/ruby

would need changing to

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.7/wrappers/ruby

after upgrading from ruby 2.1.6 to ruby 2.1.7

If you have problems, you may need to upgrade and reinstall the Passenger Phusion modules (if unsure there no harm in doing so).

Please read [Installing SEEK in a production environment](install-production.html) for more details about setting up Apache and installing the module.


## Earlier upgrade notes

For details of how to upgrade to 0.23.x and for earlier versions please visit
[Upgrades to 0.23 and earlier](earlier-upgrades.html)
