FROM ruby:3.1-slim-bullseye

LABEL maintainer="Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall"
ARG SOURCE_COMMIT
ENV APP_DIR /seek
ENV RAILS_ENV=production

# need to set the locale, otherwise some gems file to install
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:UTF-8" LC_ALL="C.UTF-8"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential cmake curl default-mysql-client gettext graphviz git \
		libcurl4-gnutls-dev libmagick++-dev libmariadb-dev libpq-dev libreadline-dev \
		libreoffice libsqlite3-dev libssl-dev libxml++2.6-dev \
		libxslt1-dev locales nginx nodejs openjdk-11-jdk-headless \
		python3.9-dev python3.9-distutils python3-pip \
		poppler-utils postgresql-client shared-mime-info sqlite3 links telnet vim-tiny zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

RUN mkdir -p $APP_DIR
RUN chown -R www-data $APP_DIR /var/www

USER www-data

WORKDIR $APP_DIR

# Bundle install throw errors if Gemfile has been modified since Gemfile.lock
COPY Gemfile* ./
RUN bundle config --local frozen 1 && \
    bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install

# App code
COPY . .
RUN mkdir log tmp
COPY docker/virtuoso_settings.docker.yml config/virtuoso_settings.yml

USER root
RUN if [ -n "$SOURCE_COMMIT" ] ; then echo $SOURCE_COMMIT > config/.git-revision ; fi
RUN chown -R www-data solr config docker public /var/www db/schema.rb
USER www-data
RUN touch config/using-docker #allows us to see within SEEK we are running in a container

# Python dependencies from requirements.txt
ENV PATH="/var/www/.local/bin:$PATH"
RUN python3.9 -m pip install setuptools==58
RUN python3.9 -m pip install -r requirements.txt

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db && \
    cp docker/database.docker.sqlite3.yml config/database.yml && \
    chmod +x docker/upgrade.sh docker/start_workers.sh && \
    bundle exec rake db:setup


RUN bundle exec rake assets:precompile && \
    rm -rf tmp/cache/*

#root access needed for next couple of steps
USER root

# Install supercronic - a cron alternative
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Cleanup and remove default nginx index page
RUN rm -rf /tmp/* /var/tmp/* /usr/share/nginx/html/index.html

USER www-data

# Network
EXPOSE 3000

# Shared
VOLUME ["/seek/filestore", "/seek/sqlite3-db", "/seek/tmp/cache", "/seek/public/assets"]

CMD ["docker/entrypoint.sh"]
