FROM ruby:2.1

MAINTAINER Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall

ENV APP_DIR /seek
ENV RAILS_ENV=production

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libssl-dev build-essential git libreadline-dev \
            libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev \
            poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev ruby2.1 ruby2.1-dev \
            nodejs build-essential mysql-client postgresql-client nginx \
            telnet vim links && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $APP_DIR

WORKDIR $APP_DIR

# Bundle install throw errors if Gemfile has been modified since Gemfile.lock
COPY Gemfile* ./
RUN bundle config --global frozen 1 && \
    bundle install 

# App code (picky about what gets copied to make caching of the assets:precompile more likely)
COPY . .

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db && \
    cp docker/database.docker.sqlite3.yml config/database.yml && \
    bundle exec rake db:setup

RUN bundle exec rake assets:precompile

# Docker specific configs
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Cleanup
RUN rm -rf /tmp/* /var/tmp/*

# Network
EXPOSE 3000

# Shared
VOLUME ["/seek/filestore", "/seek/sqlite3-db"]

CMD ["docker/entrypoint.sh"]
