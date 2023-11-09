---
title: other distributions
layout: page
redirect_from: "/other-distributions.html"
---

# Installing SEEK for other Linux distributions

Our main [Install Guide](install.html) is based upon the Ubuntu 18.04
(LTS) distribution and version. However, other than the distribution packages
the install process should be very similar for other distributions.

For some other common distributions, we describe here the required
distribution packages, and any other differences we are aware of from our
general install guide.


## Linux Mint 18

There shoudn't be any problems once SEEK is installed and
running. The only difference we have found is that MySql doesn't ask for a root password when installing the packages.
To initially connect to mysql to setup permissions you may need to do the following:

    sudo mysql -u root

## Fedora 20 / RHEL / CentOS

This installation was carried out using Fedora 20, but most likely also
applies, or is a good starting point, for Red Hat Enterprise Linux, CentOS and
other Red Hat based Linux distributions.

Many thanks to **Jay Moore** for his contributed feedback from his own
experiences installing SEEK on RHEL.

### Packages

The package names are quite different for Red Hat and are installed using
*Yum*. The packages you need to install are

    sudo yum install mysql-server

This actually installed *MariaDB*, but it is compatible and not a problem. The
rest of the packages (included those for running SEEK with Apache) are
installed as follows

    sudo yum groupinstall "Development Tools" "Development Libraries"
    sudo yum install wget curl mercurial ruby openssl-devel  openssh-server git readline-devel
    sudo yum install libxml2-devel libxml++-devel java-1.7.0-openjdk-devel sqlite-devel
    sudo yum install poppler-utils libreoffice mysql-devel mysql-libs ImageMagick-c++-devel libxslt-devel
    sudo yum install libtool gawk libyaml-devel autoconf gdbm-devel ncurses-devel automake bison libffi-devel
    sudo yum install httpd-itk httpd-devel

### Installing RVM

Install as usual following the [INSTALL guide](install.html) but pay
particular attention to any messages it reports about updating your .profile
or .bash_profile

### Installing Gems

As with Linux Mint and Ubuntu 14.04, you should run the following command
before running *bundle install* to make sure *Nokogiri* is compiled using the
installed version of *LibXML*

    bundle config build.nokogiri --use-system-libraries

### Setting up the database

Fedora installs *MariaDB* instead of *Mysql*. You may need to start up the
database with:

    sudo service mariadb start

To make it start at boot-time (this wasn't enabled by default for me) you
should run:

    sudo chkconfig mariadb on

To connect to the database to setup the user for SEEK do:

    sudo mariadb

Otherwise everything else is the same.

### Setting up for production with Passenger Phusion

To start and stop *Apache* you need to use

    sudo apachectl start
    sudo apachectl stop

Also, as with MariaDB, it wasn't set to start at boot-time, so to fix this
run:

    sudo chkconfig httpd on

The user apache runs under is *apache* rather than *www-data* so to create a
home directory for that user do:

    sudo apachectl stop
    sudo usermod -d /home/apache apache
    sudo usermod -s /bin/bash apache
    sudo mkdir /home/apache
    sudo chown apache /home/apache
    sudo apachectl start

and instead of using www-data, to switch to that user use:

    sudo su - apache

and then proceed with the normal installation, along with the differences to
installing the gems and setting up the database described earlier, until you
get to install and setup Passenger Phusion.

Before creating the Passenger module, I first need to set the following
variable to ensure it was built using a 64bit architecture

    export ARCHFLAGS="-arch x86_64"

and then proceed to run

    bundle exec passenger-install-apache2-module

I got some warnings about *FORTIFY_SOURCE requires compiling with
optimization* which I ignored and didn't seem to cause any problems.

At the end compiling and setting up Passenger Phusion, some details about the
configuration to apply to Apache are displayed. This should be applied to a
config file in */etc/httpd/conf.d/*. For e.g. I used a file
*/etc/httpd/conf.d/seek.conf*. You should also remove the other conf files
that are put there by default. The contents of this file ended up looking like
the following, although yours may differ slightly in terms of the versions
used.

    LoadModule passenger_module "/home/apache/.rvm/gems/ruby-2.1.2@seek/gems/passenger-4.0.45/buildout/apache2/mod_passenger.so"
    <IfModule mod_passenger.c>
       PassengerRoot /home/apache/.rvm/gems/ruby-2.1.2@seek/gems/passenger-4.0.45
       PassengerDefaultRuby /home/apache/.rvm/gems/ruby-2.1.2@seek/wrappers/ruby
    </IfModule>

    <VirtualHost *:80>
        # !!! Be sure to point DocumentRoot to 'public'!
        DocumentRoot /srv/rails/seek/public
        <Directory /srv/rails/seek/public>
           # This relaxes Apache security settings.
           AllowOverride all
           # MultiViews must be turned off.
           Options -MultiViews
           # Uncomment this if you're on Apache >= 2.4:
           Require all granted
        </Directory>
    </VirtualHost>

Afterwards, apache should be restarted with

    sudo apachectl restart

Now, I encountered a permission error with loading the module, which I tracked
down as being related to SELinux. To get around this I turned off SELinux with

    sudo setenforce 0

There is a description of how to be able to re-enable this at
http://sergiy.kyrylkov.name/2012/02/26/phusion-passenger-with-apache-on-rhel-6
-centos-6-sl-6-with-selinux but we have been unable to get this to work.

If you have a solution on how to re-enable SELinux, please contact us. You can
find details about how to contact us at https://seek4science.org/contact


## Ubuntu 10.04 (LTS)

The general packages:

    sudo apt-get install wget curl mercurial ruby rdoc ri libopenssl-ruby ruby-dev mysql-server libssl-dev build-essential openssh-server git-core
    sudo apt-get install libmysqlclient16-dev libmagick++-dev libxslt-dev libxml++2.6-dev openjdk-6-jdk libsqlite3-dev sqlite3
    sudo apt-get install poppler-utils openoffice.org openoffice.org-java-common

To avoid being prompted during the Ruby 1.9.3 installation with RVM:

    sudo apt-get install libreadline6-dev libyaml-dev autoconf libgdbm-dev libncurses5-dev automake bison libffi-dev

To install the Passenger Phusion module to run SEEK with Apache:

    sudo apt-get install apache2-mpm-prefork apache2-prefork-dev libapr1-dev libaprutil1-dev libcurl4-openssl-dev

The command to start soffice is also slightly different, using just single
rather than double hyphens for the arguments:

    soffice -headless -accept="socket,host=127.0.0.1,port=8100;urp;" -nofirststartwizard > /dev/null 2>&1 &

If you find the conversion of documents to PDF (for View Content in the
browser) is slow, you can install a more recent LibreOffice 3.5 from a
separate repository - although this may affect future Operating System
upgrades:

    sudo apt-get purge openoffice* libreoffice*
    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:libreoffice/libreoffice-3-5
    sudo apt-get update
    sudo apt-get install libreoffice

## Debian

By default, the user you create for Debian during the installation is not
added to the sudoers list. You may want to add your user to the *sudo* group
e.g

    adduser fred sudo

more details can be found at https://wiki.debian.org/sudo

Alternatively, when following the installation run commands that start with
*sudo* as the root user.

The required package names are just the same as for Ubuntu 12.04 - so just
follow the install guide.

If you encounter issues related to *rvm use* - you may need to configure your
terminal to run commands as a login shell. There is a checkbox that can be
found under the menu *Edit*, *Profile Preferences* and then under the tab
*Title and Command*.

# Installing SEEK for Mac OS X

*Though you can run Seek on Mac OS, you might encounter random issues and need to do several adaptations, some listed below. Some versions of several Ruby Gems are not fully functional or cannot be installed on Mac OS. It is thus strongly recommended to install Seek in a virtual machine, preferably running Ubuntu.*

## Catalina

This section will guide you to install prerequisite packages, for other steps
please read the main [Install Guide](install.html)

You will need first to install Fink and MacPorts, two package manager tools
for Mac OS X. Most of the packages will be installed by Finks, while some will
be installed by MacPorts Follow this link to install Fink:
http://www.finkproject.org/download/index.php?phpLang=en and for MacPorts:
https://www.macports.org/install.php

### Installing packages

    sudo fink install wget curl openssl100-dev git readline6
    sudo fink install libxml++2 sqlite3-dev sqlite3
    sudo fink install poppler-bin mysql-unified-dev

    sudo port install mysql8-server
    sudo port install openssh ImageMagick libxslt

For the following packages, you download the dmg image and install manually:

    Libreoffice (alternative open office): http://www.libreoffice.org/download
    Java JDK: http://www.oracle.com/technetwork/java/javase/downloads/index.html or https://jdk.java.net/ (openjdk)
    PostGres: https://www.postgresql.org/download/macosx/
    Node.js: https://nodejs.org/en/download/
    
### Setting up MySQL:

https://trac.macports.org/wiki/howto/MySQL

Important steps after installation:

Select mysql8 at the default mysql:

    sudo port select mysql mysql8
    
Start the server:

    sudo port load mysql8-server     
    
Initialize the database.

Doing so will give you a temporary root password. You **need** to write it down as it will be (very) difficult to reset it afterwards. At the first actual use of mysql (using the mysql command), you will need to change the root password (see below).
    
    sudo /opt/local/lib/mysql8/bin/mysqld --initialize --user=_mysql

First start of mysql:

    mysql -uroot -p
-> use given password

You cannot do anything before you set up a new password for root:

    ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpassword';

MySql has a new authentication method by default. To ensure that Seek can connect to it, you need to specify that the Seek DB user (set in Database.yml) can use the old "native password" method:

    ALTER USER 'seekmainuser'@'localhost' IDENTIFIED WITH mysql_native_password

Then activate the new privileges:

    flush privileges;

### PostGres Gem install

To install PostGres support using Gem, it needs the path to the binaries of it:
    sudo PATH=$PATH:/Library/PostgreSQL/x.y/bin gem install pg

for PostGres 10 for instance, it would be:
    sudo PATH=$PATH:/Library/PostgreSQL/10/bin gem install pg

### Puma Gem install

Puma needs an option to compile with the new Xcode:

    gem install puma:4.3.5 -- --with-cflags="-Wno-error=implicit-function-declaration"

### Other notes

By default, mysql client connects to mysql server through socket at
/tmp/mysql.sock. However, you might install by default the .sock file at
/opt/local/var/run/mysql8/mysqld.sock. Therefore, the .sock file needs to be
re-configured in database.yml

    socket: /opt/local/var/run/mysql8/mysqld.sock

And also when you want to run mysql client, you need to give the .sock file
path under option -S

You might need to specify the installed location of Libreoffice before running
soffice command. E.g. you might add the following line into ~/.bashrc

    export PATH="$PATH:/Applications/LibreOffice.app/Contents/MacOS/"


### Connect to MySQL from a client

By default MacPorts deactivates fully remote connections, which are needed for most SQL clients. To activate it, you can edit the my.cnf:

    sudo vim /opt/local/etc/mysql8/my.cnf

```shell
# Use default MacPorts settings
# !include /opt/local/etc/mysql8/macports-default.cnf

[client]
port                   =  3306
socket                 = /opt/local/var/run/mysql8/mysqld.sock
default-character-set  =  utf8

[mysqld_safe]
socket                 = /opt/local/var/run/mysql8/mysqld.sock
nice                   =  0 
default-character-set  = utf8

[mysqld]
basedir="/opt/local"
socket                 =  /opt/local/var/run/mysql8/mysqld.sock
port                   = 3306
bind-address           =  127.0.0.1
skip-external-locking
#skip-networking
character-set-server   =  utf8

[mysqldump]
default-character-set  =  utf8
```
    
Then restart MySQL (you might need to kill the process):

    sudo port unload mysql8-server 
    
    ps -ax | grep mysql
-> if mysqld still there, using the listed PID:

    sudo kill PID
   
then

    sudo port load mysql8-server 
