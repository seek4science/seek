# Base
FROM phusion/passenger-ruby21

# Packages - TODO: Check how many of these are actually necessary
RUN apt-get update -qq
RUN apt-get install -y wget curl mercurial libssl-dev build-essential openssh-server git libreadline-dev \
                            libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev \
                            poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev \
                            nodejs build-essential


# Update Ruby and Bundler
RUN apt-get install -y ruby2.1 ruby2.1-dev
RUN gem update bundler

# Environment
WORKDIR /home/app/seek
ENV RAILS_ENV production

RUN chown -R app:app /home/app

# Gems
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# App code
ADD . .

# Temp Database (for asset compilation)
RUN cp config/database.sqlite.yml config/database.yml
RUN bundle exec rake db:setup

# Compile assets
RUN bundle exec rake assets:precompile

# Config
RUN cp docker/database.docker.yml config/database.yml
RUN cp docker/seek_local.rb config/initializers/seek_local.rb
RUN cp config/sunspot.default.yml config/sunspot.yml

# Passenger stuff
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD docker/nginx.conf /etc/nginx/sites-enabled/seek.conf

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* db/*.sqlite3

# Network
EXPOSE 80

# Shared
VOLUME ["/home/app/seek/filestore", "/home/app/seek/config", "/home/app/seek/log"]
