#! /bin/bash
###############################################################
#
#   Copyright 2019 MarkLogic Corporation.  All Rights Reserved.
#
###############################################################
#   initialise and start MarkLogic server
#
#   ex.
#   > start-marklogic.sh
#
###############################################################

cd ~


################################################################
# Install Converters if required
################################################################
if [[ -z $INSTALL_CONVERTERS ]] ; then
    echo "Not Installing Converters"
else
    if [[ ! -d "/opt/MarkLogic/Converters" ]]; then
        echo "Installing Converters"
        CONVERTERS_PATH="/opt/converters.rpm"
        sudo yum localinstall -y $CONVERTERS_PATH
    else
        echo "Converters directory: /opt/MarkLogic/Converters already exists, skipping installation"
    fi
fi


################################################################
# Setup timezone
################################################################
if [ ! -z $TZ ]; then 
    sudo ln -snf /usr/share/zoneinfo/$TZ /etc/localtime 
    echo $TZ | sudo tee /etc/timezone
fi


################################################################
# start MarkLogic service
################################################################
if [ -z $MARKLOGIC_DEV_BUILD ]
then
sudo service MarkLogic start
else
echo "MARKLOGIC_DEV_BUILD is defined, starting using ${MARKLOGIC_INSTALL_DIR}/MarkLogic"
sudo ${MARKLOGIC_INSTALL_DIR}/MarkLogic -i . -d $MARKLOGIC_DATA_DIR -p ${MARKLOGIC_PID_FILE} &
fi
sleep 5s

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

################################################################
# check bootstrap marklogic (eg. MARKLOGIC_INIT is set)
################################################################
if [ -z $MARKLOGIC_INIT ]
then
echo "MARKLOGIC_INIT is not defined, no bootstrap"
else
echo "MARKLOGIC_INIT is defined, bootstrapping"

################################################################
# generate JSON payload conditionally with license details.
################################################################
if [[ -z $LICENSE_KEY ]] || [[ -z $LICENSEE ]]
then
LICENSE_PAYLOAD="{}"
else
echo "LICENSE_KEY and LICENSEE are defined, generating license payload"
LICENSE_PAYLOAD="{\"license-key\" : \"$LICENSE_KEY\",\"licensee\" : \"$LICENSEE\"}"
fi

################################################################
# run init requests via curl.
################################################################
curl --anyauth -i -X POST \
    -H "Content-type:application/json" \
    -d "$LICENSE_PAYLOAD" \
    http://$HOSTNAME:8001/admin/v1/init
sleep 5s
curl -X POST -H "Content-type: application/x-www-form-urlencoded" \
     --data "admin-username=$ML_ADMIN_USERNAME" --data "admin-password=$ML_ADMIN_PASSWORD" \
     --data "realm=public" \
     http://$HOSTNAME:8001/admin/v1/instance-admin
sleep 5s
fi

################################################################
# check join cluster (eg. MARKLOGIC_JOIN_CLUSTER is set)
################################################################
if [ -z $MARKLOGIC_JOIN_CLUSTER ]
then
echo "MARKLOGIC_JOIN_CLUSTER is not defined, not joining cluster"
else
echo "MARKLOGIC_JOIN_CLUSTER is defined, joining cluster"
sleep 5s
/usr/local/bin/join-cluster.sh $MARKLOGIC_BOOTSTRAP_HOST $HOSTNAME
fi

################################################################
# tail ErrorLog for docker logs
################################################################
tail -f $MARKLOGIC_DATA_DIR/Logs/ErrorLog.txt
