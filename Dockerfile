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
RUN chown www-data $APP_DIR

USER www-data

WORKDIR $APP_DIR

# Bundle install throw errors if Gemfile has been modified since Gemfile.lock
COPY Gemfile* ./
RUN bundle config --local frozen 1 && \
    bundle install --deployment --without development test

# App code
COPY . .
RUN mkdir log tmp

USER root
RUN chown -R www-data solr config docker/upgrade.sh public
USER www-data

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db && \
    cp docker/database.docker.sqlite3.yml config/database.yml && \
    chmod +x docker/upgrade.sh && \
    bundle exec rake db:setup


RUN bundle exec rake assets:precompile

#root access needed for next couple of steps
USER root

# NGINX config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Cleanup
RUN rm -rf /tmp/* /var/tmp/*

USER www-data

# Network
EXPOSE 3000

# Shared
VOLUME ["/seek/filestore", "/seek/sqlite3-db"]

CMD ["docker/entrypoint.sh"]
