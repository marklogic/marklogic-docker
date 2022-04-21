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
# Read in ENV values
################################################################

# If an ENV value exists in a list Append it the /etc/marklogic.conf file 
if [[ -z $OVERWRITE_ML_CONF ]] || [[ "$OVERWRITE_ML_CONF" = "false" ]] ; then
    echo "Not writing to /etc/marklogic.conf"
else
    echo "Deleting previous /etc/marklogic.conf ,if it exists, and overwriting with env variables"
    rm -f /etc/marklogic.conf
    sudo touch /etc/marklogic.conf && sudo chmod 777 /etc/marklogic.conf

    [[ $MARKLOGIC_USER ]] && sudo echo "export MARKLOGIC_USER=$MARKLOGIC_USER" >> /etc/marklogic.conf
    [[ $MARKLOGIC_PID_FILE ]] && sudo echo "export MARKLOGIC_PID_FILE=$MARKLOGIC_PID_FILE" >> /etc/marklogic.conf
    [[ $MARKLOGIC_UMASK ]] && sudo echo "export MARKLOGIC_UMASK=$MARKLOGIC_UMASK" >> /etc/marklogic.conf
    [[ $MARKLOGIC_DISABLE_JVM ]] && sudo echo "export MARKLOGIC_DISABLE_JVM=$MARKLOGIC_DISABLE_JVM" >> /etc/marklogic.conf
    [[ $TZ ]] && sudo echo "export  TZ=$TZ " >> /etc/marklogic.conf
    [[ $MARKLOGIC_CLUSTER_NAME ]] && sudo echo "export MARKLOGIC_CLUSTER_NAME=$MARKLOGIC_CLUSTER_NAME" >> /etc/marklogic.conf
    [[ $MARKLOGIC_NODE_NAME ]] && sudo echo "export MARKLOGIC_NODE_NAME=$MARKLOGIC_NODE_NAME" >> /etc/marklogic.conf
    [[ $MARKLOGIC_ADMIN_USERNAME ]] && sudo echo "export MARKLOGIC_ADMIN_USERNAME=$MARKLOGIC_ADMIN_USERNAME" >> /etc/marklogic.conf
    [[ $MARKLOGIC_ADMIN_PASSWORD ]] && sudo echo "export MARKLOGIC_ADMIN_PASSWORD=$MARKLOGIC_ADMIN_PASSWORD" >> /etc/marklogic.conf
    [[ $MARKLOGIC_CLUSTER_MASTER ]] && sudo echo "export MARKLOGIC_CLUSTER_MASTER=$MARKLOGIC_CLUSTER_MASTER" >> /etc/marklogic.conf
    [[ $MARKLOGIC_LICENSEE ]] && sudo echo "export MARKLOGIC_LICENSEE=$MARKLOGIC_LICENSEE" >> /etc/marklogic.conf
    [[ $MARKLOGIC_LICENSE_KEY ]] && sudo echo "export MARKLOGIC_LICENSE_KEY=$MARKLOGIC_LICENSE_KEY" >> /etc/marklogic.conf
    [[ $MARKLOGIC_DISABLE_JVM ]] && sudo echo "export MARKLOGIC_DISABLE_JVM=$MARKLOGIC_DISABLE_JVM" >> /etc/marklogic.conf
    [[ $JAVA_HOME ]] && sudo echo "export JAVA_HOME=$JAVA_HOME" >> /etc/marklogic.conf
    [[ $CLASSPATH ]] && sudo echo "export CLASSPATH=$CLASSPATH" >> /etc/marklogic.conf
    [[ $ML_HUGEPAGES_TOTAL ]] && sudo echo "export ML_HUGEPAGES_TOTAL=$ML_HUGEPAGES_TOTAL" >> /etc/marklogic.conf

    sudo chmod 400 /etc/marklogic.conf
fi




################################################################
# Install Converters if required
################################################################
if [[ -z $INSTALL_CONVERTERS ]] || [[ "$INSTALL_CONVERTERS" = "false" ]] ; then
    echo "Not Installing Converters"
else
    if [[ -d "/opt/MarkLogic/Converters" ]]; then
        echo "Converters directory: /opt/MarkLogic/Converters already exists, skipping installation"
    else
        echo "Installing Converters"
        CONVERTERS_PATH="/converters.rpm"
        sudo yum localinstall -y $CONVERTERS_PATH
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
if [ -z $MARKLOGIC_INIT ] || [[ "$MARKLOGIC_INIT" = "false" ]]
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
if [ -z $MARKLOGIC_JOIN_CLUSTER ] || [[ "$MARKLOGIC_JOIN_CLUSTER" = "false" ]]
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
