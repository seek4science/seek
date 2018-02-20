---
title: upgrading seek
layout: page
redirect_from: "/upgrading.html"
---

# Upgrading SEEK

If you have an existing SEEK installation, and you haven't done so already,
please take a moment to fill out our very short,optional [SEEK Registration
Form](http://www.seek4science.org/seek-registration). Doing so will be very useful
to us in the future when we try and raise further funding to develop and
support SEEK and the associated tools.

**Always backup your SEEK data before starting to upgrade!!** - see the
[Backup Guide](backups.html).

This guide assumes that SEEK has been installed following the [Installation
Guide](install.html) guide. It assumes it is a production server that is
being updated, and that commands are run from the root directory of the SEEK
application.


## Identifying your version

The version of SEEK you are running is shown at the bottom left, within the
footer, when viewing pages in SEEK.

You can also tell which version you have installed by looking at the
*config/version.yml* file, so for example version 0.13.2 looks something like:

    major: 0
    minor: 13
    patch: 2


## Upgrading between patch versions (e.g. between 1.4.0 and 1.4.1) 

It should only be necessary to run *bundle install* and the *db:migrate* rake
task. Using *seek:upgrade* should still work, but could take a lot of
unnecessary time. 

## Steps to upgrade from 1.4.x to 1.5.x


### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull
    git checkout v1.5.2

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.5.2.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.5.2.tar.gz
    mv seek seek-previous
    mv seek-1.5.2 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Update RVM and Ruby

    rvm get stable
    rvm install $(cat .ruby-version) 

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd .. && cd seek #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while
    
**Note**: During the upgrade, and items that previously were shared with _All registered users_ have had their permissions updated,
and this permission has been transferred to its associated projects. An audit CSV file is created, tmp/all-users-policy-update-audit-<timestamp>.csv .
This file contains a list of all the items affected, along with the contributor and project ids.    
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                
            
    
---
    
## Earlier upgrade notes

For details of how to upgrade between earlier versions please visit
[Upgrades between earlier versions](earlier-upgrades.html)
