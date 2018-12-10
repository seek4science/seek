FROM ruby:2.4

MAINTAINER Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall

ENV APP_DIR /seek
ENV RAILS_ENV=production

# need to set the locale, otherwise some gems file to install
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:UTF-8" LC_ALL="C.UTF-8"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential git \
		libcurl4-gnutls-dev libmagick++-dev libpq-dev libreadline-dev \
		libreoffice libsqlite3-dev libssl-dev libxml++2.6-dev \
		libxslt1-dev locales mysql-client nginx nodejs openjdk-8-jdk \
		poppler-utils postgresql-client sqlite3 links telnet vim-tiny  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

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
COPY docker/virtuoso_settings.docker.yml config/virtuoso_settings.yml

USER root
RUN chown -R www-data solr config docker public /var/www db/schema.rb
USER www-data
RUN touch config/using-docker #allows us to see within SEEK we are running in a container

RUN cp docker/database.docker.mysql.yml config/database.yml

RUN bundle exec rake assets:precompile && \
    rm -rf tmp/cache/*

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
VOLUME ["/seek/filestore", "/seek/tmp/cache"]

CMD ["docker/entrypoint.sh"]
