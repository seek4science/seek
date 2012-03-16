#!/bin/sh


read -p "Login: " username


stty -echo
read -p "Password: " password
stty echo

echo

read -p "Path: " url

read -p "Number of requests: " n

for c in 1 5 10
do
	ab -n $n -c $c -A$username:$password $url
done

