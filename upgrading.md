---
title: upgrading seek
layout: page
---

# Upgrading SEEK

If you have an existing SEEK installation, and you haven't done so already,
please take a moment to fill out our very short,optional [SEEK Registration
Form](http://www.sysmo-db.org/seek-registration). Doing so will be very useful
to us in the future when we try and raise further funding to develop and
support SEEK and the associated tools.

**Always backup your SEEK data before starting to upgrade!!** - see the
[Backup Guide](doc/BACKUPS.html).

This guide assumes that SEEK has been installed following the [Installation
Guide](doc/INSTALL.html) guide. It assumes it is a production server that is
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

**If upgrading from a version earlier than v0.11.x please contact us.**

**Also if upgrading from a Mercurial based SEEK to our Git one, please contact
us. Mercurial versions of SEEK are only available up to v0.21.**

You can find details on how to contact us at: http://seek4science.org/contact

When upgrading between versions greater than v0.11.x you need to upgrade to
each released minor version in order incrementally (i.e. 0.13.x -> 0.14.x ->
0.15.x -> 0.16.x, you can skip patch versions such as 0.13.3).

Each version has a tag in mercurial, which has the format of *v* prefix
followed by the version - e.g. v0.11.1, v0.13.2, v0.17.1

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

## Steps to upgrade from 0.21.x to 0.22.x

**If you need to upgrade from v0.21 based on Mercurial rather than Git or the
downloaded tarball, please contact us on our mailing lists.**

### Stopping services before upgrading

    export RAILS_ENV=production # if upgrading a production server - remember to set this again if closing and reopening the shell
    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Update Ruby with RVM

Although not critical, we recommend updating Ruby to 2.1.5. If you are using
RVM, as recommended in the installation, you can do this with:

    rvm get stable
    rvm install ruby-2.1.5

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v0.22.0

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
https://bitbucket.org/seek4science/seek/downloads/seek-0.22.0.tgz You can
unpack this file using:

    tar zxvf seek-0.22.0.tgz

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is *config/database.yml*,
and the filestore is simply *filestore/*

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes:

    cd .. && cd seek #this is to allow RVM to pick up the ruby and gemset changes
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while
    bundle exec rake seek:workers:start
    bundle exec rake sunspot:solr:start
    touch tmp/restart.txt
    bundle exec rake tmp:clear

## Earlier upgrade notes

For details of how to upgrade to 0.21.x and for earlier versions please visit
[Upgrades to 0.21 and earlier](doc/EARLIER-UPGRADES.html)
