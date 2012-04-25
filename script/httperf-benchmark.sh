#!/bin/sh
read -p "Login: " username


stty -echo
read -p "Password: " password
stty echo

echo

read -p "Server (e.g. testing.sysmo-db.org): " server
read -p "Path (e.gl /people/): " path

basicauth=`echo -n "$username:$password" | base64`

read -p "num-conn: " nconn
read -p "num-call: " ncall
read -p "rate: " rate


httperf --server $server --ssl --uri $path --num-conn $nconn --num-call $ncall --rate $rate --add-header "Authorization: Basic $basicauth\n"

