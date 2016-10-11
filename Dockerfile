FROM ruby:2.1

MAINTAINER Stuart Owen <orcid.org/0000-0003-2130-0865>, Finn Bacall

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libssl-dev build-essential git libreadline-dev \
            libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev \
            poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev ruby2.1 ruby2.1-dev \
            nodejs build-essential mysql-client postgresql-client nginx \
            telnet vim links && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV RAILS_ENV=production

# Bundle install throw errors if Gemfile has been modified since Gemfile.lock
COPY Gemfile* ./
RUN bundle config --global frozen 1 && \
    bundle install --without development test

# App code
COPY . .

# SQLite Database (for asset compilation)
RUN cp config/database.sqlite.yml config/database.yml && \
    bundle exec rake db:setup
RUN bundle exec rake assets:precompile

# Docker specific configs
COPY docker docker
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Cleanup
RUN rm -rf /tmp/* /var/tmp/*

# Network
EXPOSE 80

# Shared
VOLUME ["/usr/src/app/filestore", "/usr/src/app/db"]

CMD ["docker/entrypoint.sh"]
