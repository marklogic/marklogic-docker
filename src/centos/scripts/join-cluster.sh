#! /bin/bash
###############################################################
#
#   Copyright 2019 MarkLogic Corporation.  All Rights Reserved.
#
###############################################################
#   join host to cluster
#
#   ex.
#   > join-cluster.sh mybootstrap.example.com myjoiner.example.com admin admin
#
###############################################################

################################################################
# check if admin password is a secret or env var
################################################################
SECRET_USR_FILE=/run/secrets/${MARKLOGIC_ADMIN_USERNAME_FILE}
SECRET_PWD_FILE=/run/secrets/${MARKLOGIC_ADMIN_PASSWORD_FILE}

if [[ -f "$SECRET_PWD_FILE" ]] && [[ ! -z "$(<"$SECRET_PWD_FILE")" ]]
then
echo "using docker secrets for credentials"
ML_ADMIN_PASSWORD=$(<"$SECRET_PWD_FILE")
else
echo "using ENV for credentials"
ML_ADMIN_PASSWORD=$MARKLOGIC_ADMIN_PASSWORD
fi

if [[ -f "$SECRET_USR_FILE" ]] && [[ ! -z "$(<"$SECRET_USR_FILE")" ]]
then
echo "using docker secrets for credentials"
ML_ADMIN_USERNAME=$(<"$SECRET_USR_FILE")
else
echo "using ENV for credentials"
ML_ADMIN_USERNAME=$MARKLOGIC_ADMIN_USERNAME
fi

cluster=${1:-${MARKLOGIC_BOOTSTRAP_HOST}}
joiner=${2:-localhost}
user=${3:-${ML_ADMIN_USERNAME}}
pass=${4:-${ML_ADMIN_PASSWORD}}

curl -o host.xml --anyauth --user $user:$pass -X GET -H "Accept: application/xml" \
        http://${joiner}:8001/admin/v1/server-config

curl -v --anyauth --user $user:$pass -X POST -d "group=Default" \
        --data-urlencode "server-config@./host.xml" \
        -H "Content-type: application/x-www-form-urlencoded" \
        -o cluster.zip http://${cluster}:8001/admin/v1/cluster-config

sleep 10s

curl -v --anyauth --user $user:$pass -X POST -H "Content-type: application/zip" \
        --data-binary @./cluster.zip \
        http://${joiner}:8001/admin/v1/cluster-config

sleep 10s

rm -Rf host.xml
rm -Rf cluster.zip
