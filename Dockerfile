# Base
FROM ruby:2.1.6

# Packages
RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y wget curl mercurial libssl-dev build-essential openssh-server git libreadline-dev
RUN apt-get install -y libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev
RUN apt-get install -y poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev
RUN apt-get install -y nodejs

# Environment
WORKDIR /seek
ENV RAILS_ENV production

# Gems
ADD Gemfile /seek/Gemfile
ADD Gemfile.lock /seek/Gemfile.lock
# Nokogiri fix
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install

# App code
ADD . /seek

# Config
RUN cp config/database.docker.yml config/database.yml
RUN cp config/sunspot.default.yml config/sunspot.yml

# Network
EXPOSE 3000 22

# Runtime
ENTRYPOINT ["/seek/docker/entrypoint.sh"]

# Shared
VOLUME ["/seek/filestore", "/seek/config", "/seek/log"]
