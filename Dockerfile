FROM ruby:2.1

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libssl-dev build-essential git libreadline-dev \
            libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev \
            poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev ruby2.1 ruby2.1-dev \
            nodejs build-essential mysql-client postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV RAILS_ENV=production

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install

# App code (picky about what gets copied to make caching of the assets:precompile more likely)
COPY Rakefile Rakefile
COPY config.ru config.ru
COPY app app
COPY config config
COPY db db
COPY lib lib
COPY public public
COPY spec spec
COPY script script
COPY solr solr
COPY vendor vendor

# Temp Database (for asset compilation)
RUN cp config/database.sqlite.yml config/database.yml
RUN bundle exec rake db:setup

# Compile assets
RUN bundle exec rake assets:precompile

# Config
# RUN cp docker/database.docker.yml config/database.yml
COPY docker/seek_local.rb config/initializers/seek_local.rb
COPY config/sunspot.default.yml config/sunspot.yml

COPY docker docker

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Cleanup
RUN rm -rf /tmp/* /var/tmp/* # db/*.sqlite3

# Network
EXPOSE 3000

# Shared
VOLUME ["/home/app/seek/filestore", "/home/app/seek/config", "/home/app/seek/log"]

CMD ["docker/entrypoint.sh"]
