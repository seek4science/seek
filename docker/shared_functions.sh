#!/bin/sh

# With MYSQL_SSL_CA set, connect over TLS and verify the server's certificate
# against that CA bundle, overriding the image's skip-ssl client default.
function mysql_tls_args {
    if [ ! -z $MYSQL_SSL_CA ]
    then
        echo "--ssl --ssl-ca=$MYSQL_SSL_CA --ssl-verify-server-cert"
    fi
}

function wait_for_mysql {
    while ! mysqladmin $(mysql_tls_args) ping -h $MYSQL_HOST --silent; do
            echo "WAITING FOR MYSQL"
            sleep 2
    done
}

function wait_for_database {
    while ! mysql $(mysql_tls_args) -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "desc $MYSQL_DATABASE.users" > /dev/null 2>&1
    do
            echo "WAITING FOR DATABASE"
            sleep 2
    done
}

function set_default_mysql_host {
    if [ -z $MYSQL_HOST ]
    then
        export MYSQL_HOST=db
    fi
}

function use_mysql_db {
    set_default_mysql_host
    cp docker/database.docker.mysql.yml config/database.yml
}

function check_mysql {
    if [ ! -z $MYSQL_DATABASE ]
    then
        echo "USING MYSQL"

        use_mysql_db

        wait_for_mysql

        if ! mysql $(mysql_tls_args) -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "desc $MYSQL_DATABASE.users" > /dev/null 2>&1
        then
            echo "SETTING UP MYSQL DB"
            bundle exec rake db:setup
        fi
    fi
}

# With NGINX_TLS set (1, true or yes), nginx serves HTTPS on port 3000 with a
# self-signed certificate generated at each start, for a proxy in front that
# encrypts its connection to the container but does not verify the
# certificate, such as an AWS load balancer. Otherwise it serves plain HTTP.
function configure_nginx_listen {
    case "${NGINX_TLS,,}" in
        1|true|yes)
            echo "NGINX TLS ENABLED"
            mkdir -p /tmp/nginx-tls
            openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
                -days 3650 -subj "/CN=seek" \
                -keyout /tmp/nginx-tls/key.pem -out /tmp/nginx-tls/cert.pem
            export SEEK_LISTEN="listen 3000 ssl;
                ssl_certificate /tmp/nginx-tls/cert.pem;
                ssl_certificate_key /tmp/nginx-tls/key.pem;"
            ;;
        *)
            export SEEK_LISTEN="listen 3000;"
            ;;
    esac
}

function enable_search {
    if [ ! -f config/initializers/seek_local.rb ]
    then
        cp docker/seek_local_search_enabled.rb config/initializers/seek_local_search_enabled.rb
    fi
}

function start_search {
    if [ ! -z $SOLR_PORT ]
    then
      echo "USING SOLR CONTAINER"
      enable_search      
    else
      echo "SINGLE CONTAINER SO SOLR IS DISABLED BY DEFAULT"      
    fi
}

function setup_and_start_cron {
    if [ -z $QUIET_SUPERCRONIC ]
    then
      echo "STARTING SUPERCRONIC"
      supercronic /seek/docker/seek.crontab &
    else
      echo "STARTING SUPERCRONIC (QUIET)"
      supercronic -quiet /seek/docker/seek.crontab &
    fi
}
