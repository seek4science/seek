# Base
FROM phusion/passenger-ruby21

# Packages - TODO: Check how many of these are actually necessary
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libssl-dev build-essential git libreadline-dev \
            libxml++2.6-dev openjdk-7-jdk libsqlite3-dev sqlite3 libcurl4-gnutls-dev \
            poppler-utils libreoffice libmagick++-dev libxslt1-dev libpq-dev \
            nodejs build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Update Ruby and Bundler
# RUN gem update bundler

# Environment
WORKDIR /home/app/seek
ENV RAILS_ENV production

RUN chown -R app:app /home/app

# Gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --without development

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

# Passenger stuff
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
COPY docker/nginx.conf /etc/nginx/sites-enabled/seek.conf

COPY docker/entrypoint.sh /entrypoint.sh

# Cleanup
RUN rm -rf /tmp/* /var/tmp/* # db/*.sqlite3

RUN chown -R app:app /home/app

# Network
EXPOSE 80

# Shared
VOLUME ["/home/app/seek/filestore", "/home/app/seek/config", "/home/app/seek/log"]

CMD ["/entrypoint.sh"]
