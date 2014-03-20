#!/bin/bash

#delete tmp and filestore artifacts remaining from previous tests
echo "Deleting old artifacts in tmp/ and filestore/"
rm -rf tmp/attachement_fu
rm -rf tmp/cache
rm -rf tmp/model_images
rm -rf tmp/fleximage
rm -rf tmp/test_content_blobs
rm -rf tmp/rdf
rm -rf filestore/


#rvm handling is based on example at http://pivotallabs.com/users/mbarinek/blog/articles/1450-rails-3-with-rvm-and-cruise-control

desired_ruby=ruby-1.9.3-p545
project_name=seek-0-21
rubygems=1.8.25

# remove annoying "warning: Insecure world writable dir"
function remove_annoying_warning() {
  chmod go-w $HOME/.rvm/gems/${desired_ruby}{,@{global,${project_name}}}{,/bin} 2>/dev/null
}

# enable rvm for ruby interpreter switching
source $HOME/.rvm/scripts/rvm || exit 1

# show available (installed) rubies (for debugging)
rvm list

# install our chosen ruby if necessary
rvm list | grep $desired_ruby > /dev/null || rvm install $desired_ruby || exit 1

# use our ruby with a custom gemset
rvm use ${desired_ruby}@${project_name} --create
gem_version=`gem -v`

if [ "$gem_version" != "$rubygems" ]
    then
        rvm rubygems ${rubygems} || exit 1
    else
        echo "Rubygems already version $rubygems, upgrading not required"
fi


remove_annoying_warning

# install bundler if necessary
gem list --local bundler | grep bundler || gem install bundler || exit 1

# debugging info
echo USER=$USER && ruby --version && which ruby && which bundle

# conditionally install project gems from Gemfile
bundle check || bundle install || exit 1

# remove the warning again after we've created all the gem directories
remove_annoying_warning

# finally, run rake
bundle exec rake cruise

#comment out above and uncomment this line to get more verbose test information
#bundle exec rake cruise TESTOPTS="-v"


