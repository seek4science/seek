FROM ruby:3.3-slim-trixie AS base
LABEL maintainer="Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall"
ARG SOURCE_COMMIT

ENV APP_DIR=/seek \
    RAILS_ENV=production \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Supercronic variables
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e


# need to set the locale, otherwise some gems file to install
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:UTF-8" LC_ALL="C.UTF-8"

# Install base dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl default-mysql-client gettext git graphviz libjemalloc2 libvips links locales \
    openjdk-21-jre poppler-utils postgresql-client python3.13 shared-mime-info sqlite3 telnet vim-tiny zip

# Prepare app directory
RUN mkdir -p $APP_DIR
RUN chown www-data:www-data $APP_DIR
WORKDIR $APP_DIR

# Disable ssl from the mysql client
RUN echo "[client]\nskip-ssl" > /etc/mysql/conf.d/disable-ssl.cnf

FROM base AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential cmake \
    libcurl4-gnutls-dev libmagick++-dev libmariadb-dev libpq-dev libreadline-dev \
    libreoffice libsqlite3-dev libssl-dev libxml++2.6-dev \
    libxslt1-dev libyaml-dev nodejs \
    python3.13-dev python3-setuptools python3-pip python3.13-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    locale-gen en_US.UTF-8

# create and use a dedicated python virtualenv
RUN python3.13 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy over App code from local filesystem
COPY . .

# Export the commit hash if provided at build time
RUN if [ -n "$SOURCE_COMMIT" ] ; then echo $SOURCE_COMMIT > config/.git-revision ; fi

# Install Ruby gems
RUN bundle config --local frozen 1 && \
    bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install

RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install supercronic - a cron alternative
RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Copy over virtuoso config
COPY docker/virtuoso_settings.docker.yml config/virtuoso_settings.yml

# Allows us to see within SEEK we are running in a container
RUN touch config/using-docker

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db
COPY --chown=www-data:www-data docker/database.docker.sqlite3.yml config/database.yml

# Create /var/www folder for bundler to compile dependencies into
RUN mkdir -p /var/www

# Fix permissions
RUN chown www-data:www-data config/initializers public sqlite3-db /var/www
RUN chown -R www-data:www-data public/api
RUN chmod -R 755 docker/upgrade.sh docker/start_workers.sh

# Python dependencies from requirements.txt
RUN python3.13 -m pip install --upgrade pip
RUN python3.13 -m pip install setuptools==58
RUN python3.13 -m pip install -r requirements.txt

USER www-data

RUN bundle exec rake db:setup

# Create log and tmp directories
RUN mkdir -p log tmp

RUN bundle exec rake assets:precompile && \
    rm -rf tmp/cache/*

FROM base AS runtime

# Set PATH to include python virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# Install nginx
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Bring over build time dependencies
COPY --from=builder "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=builder $APP_DIR $APP_DIR
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /usr/local/bin/supercronic /usr/local/bin/supercronic

# Cleanup and remove default nginx index page
RUN rm -rf /tmp/* /var/tmp/* /usr/share/nginx/html/index.html

# Bundler uses /var/www as path
RUN chown -R www-data /var/www

USER www-data

# Network
EXPOSE 3000

# Shared
VOLUME ["/seek/filestore", "/seek/sqlite3-db", "/seek/tmp/cache", "/seek/public/assets"]

CMD ["docker/entrypoint.sh"]
