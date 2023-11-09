---
title: Install Guide
layout: page
redirect_from: "/install.html"
---

# Installing SEEK

## Introduction

These steps describe how to install SEEK directly on the machine (_bare-metal_). 

For how to install and run using Docker, which in many cases is simpler and quicker, please read the [Docker Compose guide](docker/docker-compose.html).

If you have installed SEEK, please take a moment to fill out our very
short,optional [SEEK Registration
Form](https://seek4science.org/seek-registration)

If you have any problems or questions, you should contact us. The following
link will give you details on how to [Contact Us](/contacting_us.html)

SEEK is based upon the Ruby on Rails platform. Although the information on
this page should provide you with everything you need to get a basic
installation of SEEK up and running, some background reading on Ruby on Rails
would be beneficial if it is new to you. Documentation and resources
describing Ruby on Rails can be found at https://rubyonrails.org/documentation
.

SEEK is built upon Rails, and requires Ruby 3.1.

We recommend that you run SEEK on a Linux system. This guide is based on an
[Ubuntu (20.04 LTS)](https://releases.ubuntu.com/20.04/) system. However, running on other Linux distributions the
main difference is the name of the required packages that have to be installed
for that distribution, other than that the steps will be the same. If you want
to install on different distribution or version please visit [Other
Distributions](other-distributions.html) and see if it is listed there.



You will need to have *sudo* access on the machine you are installing SEEK, or
be able to login as root. You will also need an active internet connection
throughout the installation process.

Although possible, installing and running Ruby on Rails on a Windows system is
troublesome and is not covered here.

## Installing packages

These are the packages required to run SEEK with Ubuntu 20.04 (Desktop or
Server). For other distributions or versions please visit our [Other
Distributions](other-distributions.html) notes.

First add a repo which contains python versions that may not be available in the default repositories

    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa

Then ensure everything is up-to-date

    sudo apt update
    sudo apt upgrade

Now install the packages:

    sudo apt install build-essential cmake git graphviz imagemagick libcurl4-gnutls-dev libgmp-dev \
        libmagick++-dev libmysqlclient-dev libpq-dev libreadline-dev libreoffice libssl-dev \
        libxml++2.6-dev libxslt1-dev mysql-server nodejs openjdk-11-jdk openssh-server poppler-utils zip \
        python3.9-dev python3.9-distutils python3-pip

Installing these packages now will make installing Ruby easier later on:

    sudo apt install autoconf automake bison curl gawk libffi-dev libgdbm-dev \
        libncurses5-dev libsqlite3-dev libyaml-dev sqlite3
        
SEEK's Solr implementation currently requires Java 11, so you may need to switch the system's default Java runtime:

    sudo update-alternatives --config java
    
...and select the version named `/usr/lib/jvm/java-11-openjdk-amd64/bin/java` or similar.

## Development or Production?

The following steps are suitable for either setting up SEEK for development,
or in a production environment. However, when setting up a production
environment there are some minor differences - please visit [Installing SEEK
for Production](install-production.html)

## Getting SEEK

Now you are ready for installing SEEK. You can either install directly from Github, or by downloading the files. You can also run SEEK from Docker

### Install directly from Github

If you wish to install directly from GitHub, the latest version of SEEK is
tagged as *v{{ site.current_seek_version }}*. To fetch this run:

    git clone https://github.com/seek4science/seek.git
    cd seek/
    git checkout v{{ site.current_seek_version }}

### Download to install

Alternatively, you can download SEEK from
<https://github.com/seek4science/seek/archive/v{{ site.current_seek_version }}.tar.gz>

    wget -O seek-{{ site.current_seek_version }}.tar.gz https://github.com/seek4science/seek/archive/v{{ site.current_seek_version }}.tar.gz

then unpack the file with:

    tar zxfv seek-{{ site.current_seek_version }}.tar.gz
    mv seek-{{ site.current_seek_version }} seek
    cd seek/

## Setting up Ruby and RubyGems with RVM

We strongly encourage that you use [RVM](https://rvm.io/) for managing your
Ruby and RubyGems version. Although you can use the version that comes with
your linux distribution, it is more difficult to control the version you use
and keep up to date.

To install RVM on Ubuntu there is package available described at <https://github.com/rvm/ubuntu_rvm>, the steps being

    sudo apt-add-repository -y ppa:rael-gc/rvm
    sudo apt-get update
    sudo apt-get install rvm
    sudo usermod -a -G rvm $USER

... the guide recommends rebooting here, but logging in and out again usually works.

Other ways to install RVM can be found at <https://rvm.io/rvm/install> .

now install the appropriate version of Ruby

    rvm install $(cat .ruby-version)


## Installing Gems

First install bundler, which is used to manage gem versions

    gem install bundler

Next install the ruby gems SEEK needs ( for production see [Bundler Configuration](install-production.html#bundler-configuration) )

    bundle install

## Install Python dependencies

First, a specific version of `setuptools` needs to be installed to avoid an issue when installing dependencies

    python3.9 -m pip install setuptools==58

Then the other dependencies can be installed

    python3.9 -m pip install -r requirements.txt
    

## Setting up the Database

You first need to setup the database configuration file. You need to copy a
default version of this and then edit it:

    cp config/database.default.yml config/database.yml
    nano config/database.yml

**IMPORTANT:** you should at least change the default username and password.
Change this for each environment (development,production,test).

Now you need to grant permissions for the user and password you just used
(changing the example below appropriately). 

    > sudo mysql
    Enter password:
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 1522
    Server version: 5.5.32-0ubuntu0.12.04.1 (Ubuntu)

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    mysql> CREATE USER 'mysqluser'@'localhost' IDENTIFIED BY 'mysqlpassword';
    mysql> GRANT ALL PRIVILEGES ON *.* TO 'mysqluser'@'localhost' WITH GRANT OPTION;

Now to create the database for SEEK and seed it with the default data, run:

    bundle exec rake db:setup

You can now start SEEK for the first time, just to test things are working

    bundle exec rails server

... and visit http://localhost:3000 and a SEEK page should load.

However, before continuing, stop SEEK with CTRL+C and start up some services.

## Starting the SEEK services

This describes a quick way to start up the services SEEK needs. If setting up
a production server, following these steps is fine to check things are
working. However, you should also read the [Installation for
Production](install-production.html) guide for automating these services.

### Setting up and starting the Search Service

SEEK uses the [Apache Solr Search Engine](https://solr.apache.org/) which since SEEK v1.12 needs setting up 
separately. It is relatively straightforward and there are instructions on how to do this in [Setting Up Solr](setting-up-solr).

### Starting and Stopping the Background Service

SEEK uses [Delayed Job](https://github.com/collectiveidea/delayed_job) to
process various asynchronous jobs. It is important this service is running.

To start delayed job run:

    bundle exec rake seek:workers:start

and to stop run:

    bundle exec rake seek:workers:stop

you can also restart with

    bundle exec rake seek:workers:restart

## Starting SEEK

You can now start up SEEK again running:

    bundle exec rails server

## Creating an Administrator

When you first visit SEEK at http://localhost:3000 with no users present, you
will be prompted to create a new user. This user will be the administrator of
SEEK (you can change to or add other users in the future). Create a username
and password, and then fill out your profile, and you will be ready to use
SEEK.

You will be prompted to fill out our very short Registration form. **Please do
if you haven't done so already**, as this greatly assists the future support
and funding of SEEK.

## Final steps

If you are setting up SEEK for production use, please now return to our
[Installing SEEK for Production Guide](install-production.html).

You should also now read our [Administration Guide](administration.html)
for details of some basic tasks and settings.




