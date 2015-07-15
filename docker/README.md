# Docker

## Requirements
* Docker (version 1.6.2 or greater)
* Docker Compose (version 1.2.0 or greater)
* Port 80 must be free

## Quick start

Load the database schema and seed data:

    docker-compose run seek bundle exec rake db:setup

Start the docker containers:

    docker-compose up -d

Wait a minute for the app to boot, then visit "localhost" in your browser.

(Note: You may get a "connection was reset" error if the SEEK application has not finished booting up)
