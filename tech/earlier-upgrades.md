---
title: earlier upgrades
layout: page
redirect_from: "/earlier-upgrades.html"
---

**If upgrading from a version earlier than v0.11.x please contact us.**

**Also if upgrading from a Mercurial based SEEK to our Git one, please contact
us. Mercurial versions of SEEK are only available up to v0.21.**

You can find details on how to contact us at the [Contact Page](/contacting-us.html)

When upgrading between versions greater than v0.11.x you need to upgrade to
each released minor version in order incrementally (i.e. 0.13.x -> 0.14.x ->
0.15.x -> 0.16.x, you can skip patch versions such as 0.13.3).

Each version has a tag, which has the format of *v* prefix
followed by the version - e.g. v0.11.1, v0.13.2, v0.17.1

## Steps to upgrade from 1.11.x to 1.12.x

**Note** the requirement to setup Apache Solr, which is no longer bundled together with FAIRDOM-SEEK.

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
    git checkout v1.12.3

### Updating using the tarball

You can download the file from
<https://github.com/seek4science/seek/archive/v1.12.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.12.3.tar.gz
    mv seek seek-previous
    mv seek-1.12.3 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

### Upgrading Ruby

You are recommended to upgrade to Ruby 2.7. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) )you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install $(cat .ruby-version)

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

**Please note** - during the upgrade the step _Updating session store_ can take a long time and appear that it has frozen, so please be patient.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment --without development test
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       

### Update Cron Services

SEEK requires some cron jobs for periodic background jobs to run. To update these run:

    bundle exec whenever --update-crontab

### Setting up Apache Solr

The [Apache Solr Search Engine](https://solr.apache.org/) now needs to be set up separately.
It is relatively straightforward and there are instructions on how to do this in [Setting Up Solr](setting-up-solr).


### Restarting background job services

    bundle exec rake seek:workers:start    

## Stopping soffice

From version 1.12.0 it is no longer necessary to run soffice as a service. If you had previously set up the _/etc/init.d/soffice_ service,
you now stop and remove this (the soffice executable from LibreOffice is still required though).

---

## Steps to upgrade from 1.10.x to 1.11.x

### Upgrading Ruby

You will need to upgrade Ruby to Ruby 2.6.6. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) )you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install ruby-2.6.6

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
    git checkout v1.11.3

### Updating using the tarball

You can download the file from
<https://github.com/seek4science/seek/archive/v1.11.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.11.3.tar.gz
    mv seek seek-previous
    mv seek-1.11.3 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

**Please note** - during the upgrade the step _Updating session store_ can take a long time and appear that it has frozen, so please be patient.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment --without development test
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       

### Setup Cron Services

This version includes an update to ActiveJob and requires some cron jobs for periodic background jobs to run. To set these up run:

    bundle exec whenever --update-crontab

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                
    
    bundle exec rake tmp:clear  

---

## Steps to upgrade from 1.9.x to 1.10.x

### Upgrading Ruby

You will need to upgrade Ruby to Ruby 2.4.10. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) )you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install ruby-2.4.10

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
    git checkout v1.10.3

### Updating using the tarball

You can download the file from
<https://github.com/seek4science/seek/archive/v1.10.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.10.3.tar.gz
    mv seek seek-previous
    mv seek-1.10.3 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                
    
    bundle exec rake tmp:clear         

---

## Steps to upgrade from 1.8.x to 1.9.x

### Upgrading Ruby

You will need to upgrade Ruby to Ruby 2.4.9. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) )you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install ruby-2.4.9

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
    git checkout v1.9.1

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.9.1.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.9.1.tar.gz
    mv seek seek-previous
    mv seek-1.9.1 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                
    
    bundle exec rake tmp:clear

---    

## Steps to upgrade from 1.7.x to 1.8.x

### Upgrading Ruby

You will need to upgrade Ruby to Ruby 2.4.5. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) ) you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install ruby-2.4.5

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
    git checkout v1.8.3

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.8.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.8.3.tar.gz
    mv seek seek-previous
    mv seek-1.8.3 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                
    
    bundle exec rake tmp:clear
    
---    

## Steps to upgrade from 1.6.x to 1.7.x

### Upgrading Ruby

You will need to upgrade Ruby to Ruby 2.4.4. If you are using [RVM](https://rvm.io/) (according to the [Installation Guide](install.html) )you should be prompted to install during the standard installation steps that follow.
If you are not prompted you can install with the command:

    rvm install ruby-2.4.4


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
    git checkout v1.7.1

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.7.1.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.7.1.tar.gz
    mv seek seek-previous
    mv seek-1.7.1 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start                

    touch tmp/restart.txt
    bundle exec rake tmp:clear
    
---    

## Steps to upgrade from 1.5.x to 1.6.x

### Updating Java

This version requires at least **Java 8**. Please make sure this is installed by trying:

    java --version
    
which should report java version 1.8.0 or greater. If not, install with:

    sudo apt install openjdk-8-jdk
    java --version

if this still doesn't report the correct version you may need to do:
   
    sudo update-alternatives --config java
    
.. and select the _java-8_ version

You can also use the Oracle version of Java 8. This can be easily installed with Apt, through the 
[Oracle PPA](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04)


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
    git checkout v1.6.3

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.6.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.6.3.tar.gz
    mv seek seek-previous
    mv seek-1.6.3 seek
    cd seek/

and then copy across your existing filestore and database configuration file
from your previous installation and continue with the upgrade steps. The
database configuration file you would need to copy is _config/database.yml_,
and the filestore is simply _filestore/_

If you have a modified _config/sunspot.yml_ you will also need to copy that across.

### Doing the upgrade

After updating the files, the following steps will update the database, gems,
and other necessary changes. Note that seek:upgrade may take longer than usual if you have data stored that points to remote
content.

    cd . #this is to allow RVM to pick up the ruby and gemset changes
    gem install bundler
    bundle install --deployment
    bundle exec rake seek:upgrade
    bundle exec rake assets:precompile # this task will take a while       
       

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start
    
---    


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

    cd . #this is to allow RVM to pick up the ruby and gemset changes
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
    git checkout v1.4.1

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.4.1.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.4.1.tar.gz
    mv seek seek-previous
    mv seek-1.4.1 seek
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
   
Update your _sunspot.yml_ based on the new format in _[config/sunspot.default.yml](https://raw.githubusercontent.com/seek4science/seek/v1.4.1/config/sunspot.default.yml)_   

### Restarting services

    bundle exec rake sunspot:solr:start
    bundle exec rake seek:workers:start            

If you are running a production SEEK behing Apache, then move onto the next part. Otherwise, or you want to do a quick test,
 you can simply start SEEK again with:  
  
    bundle exec rails s    
            
    
### Upgrading Passenger Phusion
    
If you are running SEEK with Passenger, it is likely you will need to upgrade Passenger and your Apache or Ngninx configuration.
 
Please read [Serving SEEK through Apache](/tech/install-production.html#serving-seek-through-apache) for a reminder
on how to install the new version, and update your virtual host configuration accordingly.

### Note on Search results
    
Initially you won't get any search results, due to the upgrade of Sunspot/SOLR. The upgrade steps will have triggered
some jobs to rebuild the search index. How long this takes depends upon the number of items in the database and the speed of your
machine. You can track the progress by going to the Admin page of _SEEK_, and looking at _Job Queue_ under _Statistics_.

---

## Steps to upgrade from 1.2.x to 1.3.x


### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v1.3.3

### Updating using the tarball


You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.3.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.3.3.tar.gz

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

---

## Steps to upgrade from 1.1.x to 1.2.x


### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v1.2.3

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.2.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.2.3.tar.gz

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

---

## Steps to upgrade from 1.0.x to 1.1.x


### Set RAILS_ENV

**If upgrading a production instance of SEEK, remember to set the RAILS_ENV first**

    export RAILS_ENV=production

### Stopping services before upgrading

    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Update Ruby with RVM

Although not critical, we recommend updating Ruby to 2.1.9. If you are using
RVM, as recommended in the installation, you can do this with:

    rvm get stable
    rvm upgrade 2.1.7 2.1.9

The above upgrade command will copy across all previous gemsets (see:[https://rvm.io/rubies/upgrading](https://rvm.io/rubies/upgrading)).
If you have gemsets for other applications and copying them all isn't desirable, then you may want to start afresh:

    rvm install ruby-2.1.9

### Make sure bundler is installed

    gem install bundler

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v1.1.2

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-1.1.2.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.1.2.tar.gz

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

### Extra steps for a production server

If the upgrade has involved an upgrade of Ruby, and you are running a production service with Apache and Passenger Phusion, you will need
 to update the Apache config. You will need to point to the correct ruby wrapper script according to your version. The full path may differ, but for example

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.7/wrappers/ruby

would need changing to

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.9/wrappers/ruby

after upgrading from ruby 2.1.7 to ruby 2.1.9

If you have problems, you may need to upgrade and reinstall the Passenger Phusion modules (if unsure there no harm in doing so).

Please read [Installing SEEK in a production environment](install-production.html) for more details about setting up Apache and installing the module.

---

## Steps to upgrade from 0.23.x to 1.0.x

### Dependencies
libgmp-dev is needed for RedCloth with ruby 2.1.7

    sudo apt-get update
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
<https://bitbucket.org/fairdom/seek/downloads/seek-1.0.3.tar.gz> You can
unpack this file using:

    tar zxvf seek-1.0.3.tar.gz

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

### Extra steps for a production server

If the upgrade has involved an upgrade of Ruby, and you are running a production service with Apache and Passenger Phusion, you will need
 to update the Apache config. You will need to point to the correct ruby wrapper script according to your version. The full path may differ, but for example

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.6/wrappers/ruby

would need changing to

    PassengerDefaultRuby /home/www-data/.rvm/gems/ruby-2.1.7/wrappers/ruby

after upgrading from ruby 2.1.6 to ruby 2.1.7

If you have problems, you may need to upgrade and reinstall the Passenger Phusion modules (if unsure there no harm in doing so).

Please read [Installing SEEK in a production environment](install-production.html) for more details about setting up Apache and installing the module.


---

## Steps to upgrade from 0.22.x to 0.23.x


### Dependencies
You will need to install nodejs. First install this using

    sudo apt-get install nodejs

### Stopping services before upgrading

    export RAILS_ENV=production # if upgrading a production server - remember to set this again if closing and reopening the shell
    bundle exec rake seek:workers:stop
    bundle exec rake sunspot:solr:stop

### Update Ruby with RVM

Although not critical, we recommend updating Ruby to 2.1.6. If you are using
RVM, as recommended in the installation, you can do this with:

    rvm get stable
    rvm install ruby-2.1.6
    gem install bundler

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v0.23.0

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
<https://bitbucket.org/fairdom/seek/downloads/seek-0.23.0.tgz> You can
unpack this file using:

    tar zxvf seek-0.23.0.tgz

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

---

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
    gem install bundler

### Updating from GitHub

If you have an existing installation linked to our GitHub, you can fetch the
files with:

    git pull https://github.com/seek4science/seek.git
    git checkout v0.22.0

### Updating using the tarball

Starting with version 0.22, we've started making SEEK available as a download.
You can download the file from
https://bitbucket.org/fairdom/seek/downloads/seek-0.22.0.tgz You can
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

---
    
    

# Upgrades to 0.21.x and earlier

## Steps to upgrade from 0.20.x to 0.21.x

    export RAILS_ENV=production # if upgrading a production server - remember to set this again if closing and reopening the shell

    bundle exec ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop

#if using rvm do:
    rvm get stable
    rvm install ruby-2.1.3
    gem install bundler

#then:

    hg pull https://bitbucket.org/fairdom/seek -r v0.21.0
    hg update # only if no other changes have been made to your local version, if you get an error ignore it and do merge
    hg merge # only required if you've made changes since installing. If you have, you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    cd .. && cd seek #this is to allow RVM to pick up the ruby and gemset changes
    bundle install --deployment
    bundle exec rake seek:upgrade

The mechanism to start, stop and restart the delayed-job process has now
changed you you should use the rake task
seek:workers:<start|stop|restart|status>, e.g

    bundle exec rake seek:workers:start

there is a new init.d script for this described at
https://gist.github.com/e4219ec7cb161129f1c7

---

## Steps to upgrade from 0.19.x to 0.20.x

Start the upgrade following the standard steps:

    #if using rvm do:
    rvm get stable
    rvm install ruby-1.9.3-p545
    gem install bundler

    export RAILS_ENV=production # if upgrading a production server - remember to set this again if closing and reopening the shell

    ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop
    hg pull https://bitbucket.org/fairdom/seek -r v0.20.0
    hg update # only if no other changes have been made to your local version, if you get an error ignore it and do merge
    hg merge # only required if you've made changes since installing. If you have, you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade

If you are upgrading a production server, you also need to run the following
task. Be patient, as this can take a few minutes

    bundle exec rake assets:precompile

Now proceed with the rest of the usual tasks:

    bundle exec rake sunspot:solr:start # to restart the search server
    ./script/delayed_job start

    touch tmp/restart.txt
    bundle exec rake tmp:clear

If you are running through Apache, you should also add the following block to
your Apache configuration, after the Directory block:

    <LocationMatch "^/assets/.*$">
             Header unset ETag
             FileETag None
             # RFC says only cache for 1 year
             ExpiresActive On
             ExpiresDefault "access plus 1 year"
    </LocationMatch>

so it will look something like:

    <VirtualHost *:80>
         ServerName www.yourhost.com
         DocumentRoot /srv/rails/seek/public
            <Directory /srv/rails/seek/public>
             AllowOverride all
             Options -MultiViews
          </Directory>
          <LocationMatch "^/assets/.*$">
             Header unset ETag
             FileETag None
             # RFC says only cache for 1 year
             ExpiresActive On
             ExpiresDefault "access plus 1 year"
          </LocationMatch>
    </VirtualHost>

You may also need to enable a couple of Apache modules, so run:

    sudo a2enmod headers
    sudo a2enmod expires

You will then need to restart Apache

    sudo service apache2 restart
    
---    

## Steps to upgrade from 0.18.x to 0.19.x

Upgrading follows the standard steps:

    RAILS_ENV=production ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop RAILS_ENV=production
    hg pull https://bitbucket.org/fairdom/seek -r v0.19.1
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production

    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    RAILS_ENV=production ./script/delayed_job start

    touch tmp/restart.txt
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production
    
---    

## Steps to upgrade from 0.17.x to 0.18.x

The changes for Version 0.18 included upgrading Ruby to version 1.9.3 and
Rails to version 3.2 - this means the upgrade process is a little bit more
involved that usual. For this reason we have a seperate page detailing this
upgrade.

Please visit [Upgrading to 0.18](upgrading-to-0.18.html) for details of
how to do this upgrade.

---

## Steps to upgrade from 0.16.x to 0.17.x

Upgrading follows the standard steps:

    RAILS_ENV=production ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop RAILS_ENV=production
    hg pull https://bitbucket.org/fairdom/seek -r v0.17.1
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production

    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    RAILS_ENV=production ./script/delayed_job start

    touch tmp/restart.txt
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production

---

## Steps to upgrade from 0.15.x to 0.16.x

First there are additional dependencies you will need, which on Ubuntu 12.04
can be installed with:

    sudo apt-get install poppler-utils libreoffice

On Ubuntu 10.04:

    sudo apt-get install poppler-utils openoffice.org openoffice.org-java-common

Libre Office is a background service which is called by convert_office plugin,
to convert some document types (ms office documents, open office documents,
etc.) into pdf document.

The command to start libre office in headless mode and as the background
process:

    nohup soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1

If you run on production server, using apache and phusion passenger, you will
need to run the Libre Office service under www-data user. To do this it will
need to create a working directory in /var/www. The name of the directory
changes between versions, but will be called something similar to libreoffice
or .openoffice.org2. The easiest way to create this directory is to make a
note of the permissions for /var/www, then make it writable to www-data, start
the service, and then put the permissions on /var/www back to what they were
originally.

    sudo chown www-data:www-data /var/www

Then to start the service manually you use:

    nohup sudo -H -u www-data soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1

The 8100 port is used by default, if you'd like to run on another port, you
need also to synchronize the changed port with the default soffice_port
setting for convert_office plugin in config/environment.rb

We recommend the Libre Office service is setup using an init.d script,
following the same procedures for delayed job using the script found at:
https://gist.github.com/3787679

If you have problem with converting speed, you should upgrade OS to Ubuntu
12.04 to use Libre Office. Or you can install libre office 3.5 from PPA, but
there could be problems later on when upgrading OS. Here are the command to
install libre office from PPA:

    sudo apt-get purge openoffice* libreoffice*
    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:libreoffice/libreoffice-3-5
    sudo apt-get update
    sudo apt-get install libreoffice

Other than this, the remaining steps are the same standard steps are previous
versions:

    RAILS_ENV=production ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop RAILS_ENV=production
    hg pull https://bitbucket.org/fairdom/seek -r v0.16.3
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production

    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    RAILS_ENV=production ./script/delayed_job start
    touch tmp/restart.txt
---

## Steps to upgrade from 0.14.x to 0.15.x

SEEK 0.15 upgraded Rails to the latest 2 version,2.3.14. This requires an
update of Rubygems to 1.6.2. You can update rubygems directly by running

    gem update --system 1.6.2

or install from scratch by reading the INSTALL guide. You can also use
[RVM](https://rvm.io/). SEEK 0.15 also runs fine on the latest Rubygems
(currently 1.8.24) but you will get some deprecation warnings. You can check
you have the correct version of rubygems by running

    gem -v

Then you will need to install additional dependency:

    sudo apt-get install git

Once Rubygems has been updated and additional dependency has been installed,
the upgrade is the typical:

    RAILS_ENV=production ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop RAILS_ENV=production
    hg pull https://bitbucket.org/fairdom/seek -r v0.15.4
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production

    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    RAILS_ENV=production ./script/delayed_job start
    touch tmp/restart.txt

---

## Steps to upgrade from 0.13.x to 0.14.x

These are the fairly standard steps when upgrading between minor versions.
Note, the seek:upgrade task can take a while if there are many people and
assets in your SEEK, as it needs to populate some tables for the default
subscriptions (for email notifications).

    RAILS_ENV=production ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop RAILS_ENV=production
    hg pull https://bitbucket.org/fairdom/seek -r v0.14.1
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production

    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    RAILS_ENV=production ./script/delayed_job start
    touch tmp/restart.txt
---

## Steps to upgrade from 0.11.x to 0.13.x

There follows the commands required to upgrade. Anything after # are notes and
do not need to be included in the command run. There are a few additional
steps for this upgrade due to the switch from Solr to Sunspot as the search
system, and the introduction of Delayed Job for background processing.

First there is an additional dependency you will need, which on Ubuntu 10.04
or Debian can be installed with:

    sudo apt-get install libxslt-dev

on Ubuntu 12.04 this will be:

    sudo apt-get install libxslt1-dev

then the following steps will update the SEEK server:

    bundle exec rake solr:stop RAILS_ENV=production # this is specific to this upgrade, since the command to stop and start the search has changed.
    hg pull https://bitbucket.org/fairdom/seek -r v0.13.3
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment
    bundle exec rake seek:upgrade RAILS_ENV=production
    bundle exec rake sunspot:solr:start RAILS_ENV=production # to restart the search server
    bundle exec rake sunspot:solr:reindex RAILS_ENV=production  # to reindex
    bundle exec rake tmp:assets:clear RAILS_ENV=production
    bundle exec rake tmp:clear RAILS_ENV=production

SEEK v0.13.x now uses a Ruby tool called [Delayed
Job](https://github.com/tobi/delayed_job) to handle background processing
which now needs to be started using:

    RAILS_ENV=production ./script/delayed_job start

And now SEEK should be ready to restart. If running together with Passenger
Phusion as described in the install guide this is simply a case of:

    touch tmp/restart.txt

If you auto start solr with an init.d/ script - this will need updating to
reflect the change to sunspot:solr:start. The updated script should look
something like: https://gist.github.com/3143434

