#! /bin/bash
###############################################################
#
#   Copyright 2022 MarkLogic Corporation.  All Rights Reserved.
#
###############################################################
#   join host to cluster
#
#   ex.
#   > join-cluster.sh mybootstrap.example.com myjoiner.example.com admin admin
#
###############################################################

cluster=${1:-${MARKLOGIC_BOOTSTRAP_HOST}}
joiner=${2:-localhost}
user=${3:-${ML_ADMIN_USERNAME}}
pass=${4:-${ML_ADMIN_PASSWORD}}

curl -s -o host.xml --anyauth --user $user:$pass -X GET -H "Accept: application/xml" \
        http://${joiner}:8001/admin/v1/server-config

curl -s -v --anyauth --user $user:$pass -X POST -d "group=Default" \
        --data-urlencode "server-config@./host.xml" \
        -H "Content-type: application/x-www-form-urlencoded" \
        -o cluster.zip http://${cluster}:8001/admin/v1/cluster-config

sleep 10s

curl -s -v --anyauth --user $user:$pass -X POST -H "Content-type: application/zip" \
        --data-binary @./cluster.zip \
        http://${joiner}:8001/admin/v1/cluster-config

sleep 10s

rm -Rf host.xml
rm -Rf cluster.zip
