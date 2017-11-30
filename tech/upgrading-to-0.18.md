---
title: upgrading to 0.18
layout: page
redirect_from: "/upgrading-to-0.18.html"
---

# Upgrading to SEEK 0.18

## Backing up

We always recommend you backup before doing an upgrade, but in this case it is
even more important. Please read our [Backup Guide](backups.html) for
details on what to backup and some tips on how to do so.

## Upgrading a Production SEEK

If you run SEEK in a production environment, first set your environment
variable. You will need to do this if you open a new shell part way through
the backup.

    export RAILS_ENV=production

## Stopping Services

If you use init.d scripts to start and stop the Delayed Job or Solr Search
services, please stop them using that script. Otherwise do:

    ./script/delayed_job stop
    bundle exec rake sunspot:solr:stop

## Installing Package dependencies

Please install the packages described in the [Installation
Guide](install.html). If you are running a production server, please also
install the packages described in the [Production Installation
Guide](install-production.html)

## Installing Ruby 1.9.3 with RVM

If you are upgrading a production service, we recommend installing RVM as the
www-data user, or installing it system wide. Please check the [Production
Installation Guide](install-production.html) for details about creating a
home directory as www-data and how to switch to that user before carrying out
the following steps.

We strongly encourage that you use [RVM](https://rvm.io/) for managing your
Ruby and RubyGems version. Although you can use the version that comes with
your linux distribution, it is more difficult to control the version you use
and keep up to date.

To install RVM follow the steps at https://rvm.io/rvm/install . The current
basic installation method is to run:

    \curl -L https://get.rvm.io | bash

to save restarting your shell run:

    source ~/.rvm/scripts/rvm

now install Ruby 1.9.3

    rvm install ruby-1.9.3

you may be asked for your password so that some additional packages can be
installed. You will then need to wait for Ruby to be downloaded and compiled.

This version of SEEK has been developed and tested using Rubygems version
1.8.25. This is the version installed with Ruby 1.9.3 at the time of writing
this, but to be sure run:

    rvm rubygems 1.8.25

Now you just need to create the *Gemset* for SEEK. RVM allows what it calls
*Gemsets* to seperate the gems installed, in isolation from each other, for
different applications. To create the gemset run:

    rvm gemset create seek

And finally

    rvm use ruby-1.9.3@seek
    gem install bundler

## Fetching and Updating SEEK

You are now ready to fetch the SEEK code and start upgrading. Make sure your
*RAILS_ENV* is still set to *production* if necessary.

    hg pull https://bitbucket.org/fairdom/seek -r v0.18.3
    hg update
    hg merge # only required if you've made changes since installing. If you have you may need to deal with conflicts.
    hg commit -m "merged" # likewise - only required if you made changes since installing
    bundle install --deployment

You now need to edit the *config/database.yml* file, and change the *adaptor*
setting from *mysql* to *mysql2*.

If you are unsure what to change, have a look at
*config/database.default.yml*.

Then continue with:

    bundle exec rake db:migrate
    bundle exec rake seek:upgrade
    bundle exec rake tmp:assets:clear
    bundle exec rake tmp:clear

## Converting the database

This bit is a bit fiddly, but is required to update your mysql database to
correctly report UTF-8. If you know of a cleaner way to do this then please
let us know!

If your database is already UTF-8 encoded, you don't need to convert.

First refer to *config/database.yml* to check the database name, and the
username and password you use.

The following commands help you to check the current encoding, but replacing _mysql_username_ and _database_name_:

    mysql -u <mysql_username> -p <database_name>
    SHOW VARIABLES LIKE 'character_set%';

If the value of variable character_set_connection is not UTF-8, you need to
convert.

If the current encoding is latin1, please follow the next steps to convert it
to UTF-8.

First, make a dump of the database using the following:

    mysqldump -u <mysql_username> -p --opt --default-character-set=latin1 --skip-set-charset  <database_name> > seek_db.sql

Now a couple of commands to change the contents of the dump

    sed -e 's/CHARSET=latin1/CHARSET=utf8/g' seek_db.sql > seek_db_utf8.sql
    sed -e 's/COLLATE=utf8_unicode_ci//g' seek_db_utf8.sql > seek_db_converted.sql

Now refresh the database from the dump:

    mysql -u <mysql_username> -p <database_name> < seek_db_converted.sql

If you have started up SEEK before doing this conversion you may need to clear
the SEEK cache:

    bundle exec rake tmp:clear

You can now clear out the intermediate files:

    rm seek_db.sql seek_db_utf8.sql seek_db_converted.sql

## Updating the init.d scripts

If you use init.d scripts to start and stop the Delayed Job, Solr Search and
Soffice services, you may need to update these (you will need to be a user
with sudo access to update these scripts).

Solr Search - https://gist.github.com/3143434

Delayed Job - https://gist.github.com/3169625

Soffice - https://gist.github.com/3787679

## Starting up SEEK and the Services

You can now startup the services, either using the init.d scripts or by
running:

    bundle exec rake sunspot:solr:start
    ./script/delayed_job start

If you don't use SEEK with Apache, the command to start it is now:

    bundle exec rails server

### Updating Passenger Phusion

If you run SEEK with Apache, you may find you need to update and reconfigure
Apache and Passenger Phusion. Please follow the steps in this section of the
[Production Installation Guide](install-production.html)


