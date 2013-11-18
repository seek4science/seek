#!/bin/sh
#This script is used for setting up the SEEK application and its environment. It is tested on Ubuntu 12.04
#You might want to change the path and directory where SEEK is installed, by changing the values of the variables: SEEK_PATH, SEEK_DIRECTORY
#You might want to specify the repository where SEEK get cloned and its version , by changing the value of variable: REPOSITORY
#More information about each step of installation can be found at SEEK_PATH/SEEK_DIRECTORY/doc/INSTALL

SEEK_PATH="/home/$(whoami)" 
SEEK_DIRECTORY="seek"
REPOSITORY="https://bitbucket.org/seek4science/seek -r v0.17.1"

txtgrn=$(tput setaf 2) # Green
txtrst=$(tput sgr0) # Text reset

set -e

sudo sed -i 's/# deb http:\/\/archive.canonical.com\/ubuntu/deb http:\/\/archive.canonical.com\/ubuntu/g' /etc/apt/sources.list
sudo sed -i 's/# deb-src http:\/\/archive.canonical.com\/ubuntu/deb-src http:\/\/archive.canonical.com\/ubuntu/g' /etc/apt/sources.list

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Installing prequisites ${txtrst}"
sudo apt-get update
sudo apt-get install wget git mercurial ruby ri1.8 libruby1.8 ruby-dev mysql-server libssl-dev build-essential openssh-server
sudo apt-get install libmysqlclient-dev libmagick++-dev libxslt1-dev libxml++2.6-dev openjdk-6-jdk libsqlite3-dev sqlite3
sudo apt-get install poppler-utils libreoffice

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Installing rubygems ${txtrst}"
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.6.2.tgz
tar zfxv rubygems-1.6.2.tgz
cd rubygems-1.6.2/
sudo ruby ./setup.rb
cd /usr/bin/

symboliclink="gem"
if [ -L "$symboliclink" ]; then
    sudo rm "$symboliclink"
fi
sudo ln -s gem1.8 gem
cd -

if [ ! -d "$SEEK_PATH" ]; then
    mkdir "$SEEK_PATH"
fi

cd "$SEEK_PATH"
directory="$SEEK_PATH/$SEEK_DIRECTORY" 
if [ -d "$directory" ]; then
    sudo rm -rf "$directory"
fi

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Cloning SEEK from $REPOSITORY ${txtrst}"
sudo hg clone $REPOSITORY $SEEK_DIRECTORY

sudo chown -R $(whoami):$(whoami) $SEEK_PATH/$SEEK_DIRECTORY

sudo gem install -d bundler rake

if [ -d /home/$(whoami)/.gem ]; then
    sudo chown -R $(whoami):$(whoami) /home/$(whoami)/.gem
fi

cd "$SEEK_DIRECTORY"
bundle install

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Now you are setting the database for SEEK. The following step creates an account for SEEK in MySQL database. This account information later on can be found at $SEEK_PATH/$SEEK_DIRECTORY/config/database.yml  ${txtrst}"
echo "Please enter the user name:"
read user_name
echo "Please enter the password:"
stty -echo
read password
stty echo

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Now you need to enter the root password of MySQL database to create the account ${txtrst}" 
mysql -uroot -p << EOF      
   CREATE USER "$user_name"@'localhost' IDENTIFIED BY "$password";
   GRANT ALL PRIVILEGES ON *.* TO "$user_name"@'localhost' WITH GRANT OPTION;	
EOF

cp config/database.default.yml config/database.yml
sed -i "s/mysqluser/$user_name/g" "$SEEK_PATH/$SEEK_DIRECTORY/config/database.yml"
sed -i "s/mysqlpassword/$password/g" "$SEEK_PATH/$SEEK_DIRECTORY/config/database.yml"

bundle exec rake db:setup RAILS_ENV=development
bundle exec rake db:setup RAILS_ENV=production
bundle exec rake db:setup RAILS_ENV=test

bundle exec rake db:test:prepare

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} You finished setting up.${txtrst}"
echo "${txtgrn} SEEK is installed under $SEEK_PATH/$SEEK_DIRECTORY. If you run SEEK on apache, you need to install and configurate it. The steps are described at $SEEK_PATH/$SEEK_DIRECTORY/doc/INSTALL ${txtrst}"
echo "${txtgrn} You might want to start solr search engine, open office and some delayed jobs. Please read about those services and how to start at $SEEK_PATH/$SEEK_DIRECTORY/doc/INSTALL ${txtrst}"

echo "${txtgrn} *********************************** ${txtrst}"
echo "${txtgrn} Now start SEEK server under production mode ${txtrst}"
echo "${txtgrn} You might want to try out SEEK by going to: http://localhost:3000. ${txtrst}"
RAILS_ENV=production bundle exec script/server
