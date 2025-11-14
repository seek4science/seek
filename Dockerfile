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
    curl zip libjemalloc2 libvips \
    sqlite3 postgresql-client default-mysql-client \
    vim-tiny git openjdk-21-jre python3.13 \
    poppler-utils graphviz gettext shared-mime-info

# Prepare app directory
RUN mkdir -p $APP_DIR
RUN chown www-data $APP_DIR
WORKDIR $APP_DIR

# Disable ssl from the mysql client
RUN echo "[client]\nskip-ssl" > /etc/mysql/conf.d/disable-ssl.cnf

FROM base AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential cmake \
    libcurl4-gnutls-dev libmagick++-dev libmariadb-dev libpq-dev libreadline-dev \
    libreoffice libsqlite3-dev libssl-dev libxml++2.6-dev \
    libxslt1-dev libyaml-dev locales nodejs \
    python3.13-dev python3-setuptools python3-pip python3.13-venv \
    shared-mime-info links zip && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    locale-gen en_US.UTF-8

# create and use a dedicated python virtualenv
RUN python3.13 -m venv /opt/venv
RUN chown -R www-data /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy over App code from local filesystem
COPY --chown=www-data:www-data . .

USER www-data

# Create log and tmp directories
RUN mkdir log tmp


# Export the commit hash if provided at build time
RUN if [ -n "$SOURCE_COMMIT" ] ; then echo $SOURCE_COMMIT > config/.git-revision ; fi

# Install Ruby gems
RUN bundle config --local frozen 1 && \
    bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install

RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Allows us to see within SEEK we are running in a container
RUN touch config/using-docker

# Python dependencies from requirements.txt
RUN python3.13 -m pip install --upgrade pip
RUN python3.13 -m pip install setuptools==58
RUN python3.13 -m pip install -r requirements.txt

# SQLite Database (for asset compilation)
RUN mkdir sqlite3-db && \
    cp docker/database.docker.sqlite3.yml config/database.yml && \
    chmod +x docker/upgrade.sh docker/start_workers.sh && \
    bundle exec rake db:setup

RUN bundle exec rake assets:precompile && \
    rm -rf tmp/cache/*

USER root

# Install supercronic - a cron alternative
RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

FROM base AS runtime

# Set PATH to include python virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# Install nginx
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Bring over build time dependencies
COPY --from=builder --chown=www-data:www-data "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=builder --chown=www-data:www-data $APP_DIR $APP_DIR
COPY --from=builder --chown=www-data:www-data /opt/venv /opt/venv
COPY --from=builder --chown=www-data:www-data /usr/local/bin/supercronic /usr/local/bin/supercronic

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
