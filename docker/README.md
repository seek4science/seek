# Docker

## Requirements
* Docker (version 1.6.2 or greater)
* Docker Compose (version 1.2.0 or greater)
* Port 80 must be free

## Quick start

Load the database schema and seed data:

    docker-compose run seek bundle exec rake db:setup

Start the docker containers (add the argument `-d` to start the containers in "detached" mode):

    docker-compose up

Visit "localhost" in your browser.
