# Base
FROM phusion/passenger-ruby21

# Packages - TODO: Check how many of these are actually necessary
RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y wget curl mercurial libssl-dev build-essential openssh-server git libreadline-dev
RUN apt-get install -y libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev
RUN apt-get install -y poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev
RUN apt-get install -y nodejs

# Passenger stuff
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD docker/nginx.conf /etc/nginx/sites-enabled/seek.conf

# Environment
WORKDIR /home/app/seek
ENV RAILS_ENV production

# Gems
ADD Gemfile /home/app/seek/Gemfile
ADD Gemfile.lock /home/app/seek/Gemfile.lock
# Nokogiri fix
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install

# App code
ADD . /home/app/seek
RUN chown -R app:app /home/app/seek

# Temp Database (for asset compilation)
RUN cp config/database.sqlite.yml config/database.yml
RUN bundle exec rake db:setup

# Compile assets
RUN bundle exec rake assets:precompile

# Config
RUN cp docker/database.docker.yml config/database.yml
RUN cp docker/seek_local.rb config/initializers/seek_local.rb
RUN cp config/sunspot.default.yml config/sunspot.yml

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* db/*.sqlite3

# Network
EXPOSE 80

# Shared
VOLUME ["/home/app/seek/filestore", "/home/app/seek/config", "/home/app/seek/log"]
