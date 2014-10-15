#!/bin/sh
#script to automatic flipping the configurations between vln, biovel and openseek (and others in the future).
#sets the correct symbolic link for the seek_configuration, en.yml and seeds.rb

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters, you need to pass either openseek, vln, or biovel"
    exit 1
fi

if [ ! -e "Gemfile" ]
then
	echo "You need to run this from the root of the SEEK app, i.e. as script/flip_flavour.sh"
	exit 1
fi

FLAVOUR=$1

CONFIG_FILE="config/initializers/seek_configuration.rb-$FLAVOUR"
LOCALE_FILE="config/locales/en.yml-$FLAVOUR"
SEEDS_FILE="db/seeds.rb-$FLAVOUR"

if [ ! -e $CONFIG_FILE ]
then
	echo "cannot file the configuration file $CONFIG_FILE"
	exit 1
fi

if [ ! -e $LOCALE_FILE ]
then
	echo "cannot file the locale file $LOCALE_FILE"
	exit 1
fi

if [ ! -e $SEEDS_FILE ]
then
	echo "cannot file the seeds file $SEEDS_FILE"
	exit 1
fi


ln -sf "seek_configuration.rb-$FLAVOUR" config/initializers/seek_configuration.rb
ln -sf "en.yml-$FLAVOUR" config/locales/en.yml
ln -sf "seeds.rb-$FLAVOUR" db/seeds.rb

ls -l db/seeds.rb
ls -l config/locales/en.yml
ls -l config/initializers/seek_configuration.rb

echo "Updated to use $FLAVOUR succesfully"
exit
