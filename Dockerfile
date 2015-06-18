# Base
FROM phusion/passenger-ruby21

# Packages - TODO: Check how many of these are actually necessary
RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y wget curl mercurial libssl-dev build-essential openssh-server git libreadline-dev
RUN apt-get install -y libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev
RUN apt-get install -y poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev
RUN apt-get install -y nodejs

CMD ["/sbin/my_init"]

# Passenger stuff
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD nginx.conf /etc/nginx/sites-enabled/seek.conf

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

# Config
RUN cp config/database.docker.yml config/database.yml
RUN cp config/sunspot.default.yml config/sunspot.yml

# Network
EXPOSE 80

# Runtime
ENTRYPOINT ["/home/app/seek/docker/entrypoint.sh"]

# Shared
VOLUME ["/home/app/seek/filestore", "/home/app/seek/config", "/home/app/seek/log"]
