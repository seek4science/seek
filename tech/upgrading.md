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


## Upgrading between patch versions (e.g. between 1.2.0 and 1.2.2) 

It should only be necessary to run *bundle install* and the *db:migrate* rake
task. Using *seek:upgrade* should still work, but could take a lot of
unnecessary time. 

## Steps to upgrade from 1.3.x to 1.4.x


### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

**For this version, it really is critical to stop these services at this stage. You will be unable to later.**

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull
    git checkout v1.4.0

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.4.0.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.4.0.tar.gz
    mv seek seek-previous
    mv seek-{{ site.current_seek_version }} seek
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
    
### Updating the Sunspot configuration
    
If you moved away from the default Sunspot/SOLR config, by making your own copy of _config/sunspot.yml_, this will need updating.

If you don't have a _config/sunspot.yml_ you don't need to do anything.
   
Update your _sunspot.yml_ based on the new format in _[config/sunspot.default.yml](https://github.com/seek4science/seek/blob/seek-1.4/config/sunspot.default.yml)_   

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start    
    touch tmp/restart.txt
    bundle exec rake tmp:clear
    
### Note on Search results
    
Initially you won't get any search results, due to the upgrade of Sunspot/SOLR. The upgrade steps will have triggered a
some jobs to rebuild the index. How long this takes depends upon the number of items in the database and the speed of your
machine. You can track the progress by going to the Admin page of _SEEK_, and looking at _Job Queue_ under _Statistics_.
    
### Upgrading Passenger Phusion
    
If you are running SEEK with Passenger, it is likely you will need to upgrade Passenger and your Apache or Ngninx configuration.
 
Please read [Serving SEEK through Apache](/tech/install-production.html#serving-seek-through-apache) for a reminder
on how to install the new version, and update your virtual host configuration accordingly.
    
---
    
## Earlier upgrade notes

For details of how to upgrade to 1.2.x and for earlier versions please visit
[Upgrades between earlier versions](earlier-upgrades.html)
