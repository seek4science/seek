FROM ruby:2.2

MAINTAINER Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall

ENV APP_DIR /seek
ENV RAILS_ENV=production

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential git \ 
		libcurl4-gnutls-dev libmagick++-dev libpq-dev libreadline-dev \
		libreoffice libsqlite3-dev libssl-dev libxml++2.6-dev \
		libxslt1-dev mysql-client nginx nodejs openjdk-7-jdk poppler-utils \
		postgresql-client sqlite3 links telnet && \
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
RUN chown -R www-data solr config docker public /var/www db/schema.rb
USER www-data
RUN touch config/using-docker #allows us to see within SEEK we are running in a container

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db && \
    cp docker/database.docker.sqlite3.yml config/database.yml && \
    chmod +x docker/upgrade.sh docker/start_workers.sh && \
    bundle exec rake db:setup


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
VOLUME ["/seek/filestore", "/seek/sqlite3-db", "/seek/tmp/cache"]

CMD ["docker/entrypoint.sh"]
