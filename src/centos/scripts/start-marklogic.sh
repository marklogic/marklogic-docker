#! /bin/bash
###############################################################
#
#   Copyright 2022 MarkLogic Corporation.  All Rights Reserved.
#
###############################################################
#   Initialise and start MarkLogic server
#
#   ex.
#   > start-marklogic.sh
#
###############################################################

###############################################################
# Prepare script
###############################################################
cd ~ || exit
# Convert booleans to lowercase
for var in OVERWRITE_ML_CONF INSTALL_CONVERTERS MARKLOGIC_DEV_BUILD MARKLOGIC_INIT MARKLOGIC_JOIN_CLUSTER; do
  declare $var="$(echo "${!var}" | sed -e 's/[[:blank:]]//g' | awk '{print tolower($0)}')"
done

# define log and err functions
log() {
    echo "$(basename "${0}"): ${*}"
}
err() {
    echo "$(basename "${0}") ERROR: ${*}" >&2
    exit 1
}

################################################################
# Read in ENV values for marklogic.conf
################################################################

# If an ENV value exists in a list, append it to the /etc/marklogic.conf file
if [[ "${OVERWRITE_ML_CONF}" = "true" ]]; then
    log "Deleting previous /etc/marklogic.conf, if it exists, and overwriting with env variables."
    rm -f /etc/marklogic.conf
    sudo touch /etc/marklogic.conf && sudo chmod 777 /etc/marklogic.conf

    [[ "${MARKLOGIC_PID_FILE}" ]] && echo "export MARKLOGIC_PID_FILE=$MARKLOGIC_PID_FILE" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_UMASK}" ]] && echo "export MARKLOGIC_UMASK=$MARKLOGIC_UMASK" >>/etc/marklogic.conf
    [[ "${TZ}" ]] && echo "export TZ=$TZ " >>/etc/marklogic.conf
    [[ "${MARKLOGIC_ADMIN_USERNAME}" ]] && echo "export MARKLOGIC_ADMIN_USERNAME=$MARKLOGIC_ADMIN_USERNAME" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_ADMIN_PASSWORD}" ]] && echo "export MARKLOGIC_ADMIN_PASSWORD=$MARKLOGIC_ADMIN_PASSWORD" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_LICENSEE}" ]] && echo "export MARKLOGIC_LICENSEE=$MARKLOGIC_LICENSEE" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_LICENSE_KEY}" ]] && echo "export MARKLOGIC_LICENSE_KEY=$MARKLOGIC_LICENSE_KEY" >>/etc/marklogic.conf
    [[ "${ML_HUGEPAGES_TOTAL}" ]] && echo "export ML_HUGEPAGES_TOTAL=$ML_HUGEPAGES_TOTAL" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_DISABLE_JVM}" ]] && echo "export MARKLOGIC_DISABLE_JVM=$MARKLOGIC_DISABLE_JVM" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_USER}" ]] && echo "export MARKLOGIC_USER=$MARKLOGIC_USER" >>/etc/marklogic.conf
    [[ "${JAVA_HOME}" ]] && echo "export JAVA_HOME=$JAVA_HOME" >>/etc/marklogic.conf
    [[ "${CLASSPATH}" ]] && echo "export CLASSPATH=$CLASSPATH" >>/etc/marklogic.conf

    sudo chmod 400 /etc/marklogic.conf

elif [[ -z ${OVERWRITE_ML_CONF} ]] || [[ "${OVERWRITE_ML_CONF}" = "false" ]]; then
    log "Not writing to /etc/marklogic.conf"
else
    err "OVERWRITE_ML_CONF must be true or false."
fi

################################################################
# Install Converters if required
################################################################
if [[ "${INSTALL_CONVERTERS}" == "true" ]]; then
    if [[ -d "/opt/MarkLogic/Converters" ]]; then
        log "Converters directory: /opt/MarkLogic/Converters already exists, skipping installation."
    else
        log "Installing Converters"
        CONVERTERS_PATH="/converters.rpm"
        sudo yum localinstall -y $CONVERTERS_PATH
    fi
elif [[ -z "${INSTALL_CONVERTERS}" ]] || [[ "${INSTALL_CONVERTERS}" = "false" ]]; then
    log "Not Installing Converters"
else
    err "INSTALL_CONVERTERS must be true or false."
fi

################################################################
# Setup timezone
################################################################
if [ -n "${TZ}" ]; then
    log "Setting timezone to ${TZ}"
    sudo ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone
fi

################################################################
# Start MarkLogic service
################################################################
if [[ "${MARKLOGIC_DEV_BUILD}" == "true" ]]; then
    log "MARKLOGIC_DEV_BUILD is true, starting using ${MARKLOGIC_INSTALL_DIR}/MarkLogic"
    sudo "${MARKLOGIC_INSTALL_DIR}/MarkLogic" -i . -d "${MARKLOGIC_DATA_DIR}" -p "${MARKLOGIC_PID_FILE}" &
elif [[ -z "${MARKLOGIC_DEV_BUILD}" ]] || [[ "${MARKLOGIC_DEV_BUILD}" == "false" ]]; then
    sudo service MarkLogic start
else
    err "MARKLOGIC_DEV_BUILD must be true or false."
fi
sleep 5s

################################################################
# Check if admin password is a secret or env var
################################################################
SECRET_USR_FILE="/run/secrets/${MARKLOGIC_ADMIN_USERNAME_FILE}"
SECRET_PWD_FILE="/run/secrets/${MARKLOGIC_ADMIN_PASSWORD_FILE}"

if [[ -f "${SECRET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_PWD_FILE}")" ]]; then
    log "Using docker secrets for credentials."
    ML_ADMIN_PASSWORD=$(<"$SECRET_PWD_FILE")
else
    log "Using ENV for credentials."
    ML_ADMIN_PASSWORD="${MARKLOGIC_ADMIN_PASSWORD}"
fi

if [[ -f "$SECRET_USR_FILE" ]] && [[ -n "$(<"$SECRET_USR_FILE")" ]]; then
    log "Using docker secrets for credentials."
    ML_ADMIN_USERNAME=$(<"$SECRET_USR_FILE")
else
    log "Using ENV for credentials."
    ML_ADMIN_USERNAME="${MARKLOGIC_ADMIN_USERNAME}"
fi

################################################################
# check bootstrap marklogic (eg. MARKLOGIC_INIT is set)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_INIT ]]; then
    log "MARKLOGIC_INIT is already initialized, no bootstrap."
elif [[ "${MARKLOGIC_INIT}" = "true" ]]; then
    log "MARKLOGIC_INIT is true, bootstrapping."

    # generate JSON payload conditionally with license details.
    if [[ -z "${LICENSE_KEY}" ]] || [[ -z "${LICENSEE}" ]]; then
        LICENSE_PAYLOAD="{}"
    else
        log "LICENSE_KEY and LICENSEE are defined, generating license payload."
        LICENSE_PAYLOAD="{\"license-key\" : \"${LICENSE_KEY}\",\"licensee\" : \"${LICENSEE}\"}"
    fi

    log "Bootstrapping MarkLogic on ${HOSTNAME}."
    curl -s --anyauth -i -X POST \
        -H "Content-type:application/json" \
        -d "${LICENSE_PAYLOAD}" \
        "http://${HOSTNAME}:8001/admin/v1/init"
    sleep 5s
    curl -s -X POST -H "Content-type: application/x-www-form-urlencoded" \
        --data "admin-username=${ML_ADMIN_USERNAME}" --data "admin-password=${ML_ADMIN_PASSWORD}" \
        --data "realm=public" \
        "http://${HOSTNAME}:8001/admin/v1/instance-admin"
    sleep 5s
    sudo touch /opt/MarkLogic/DOCKER_INIT
elif [[ -z "${MARKLOGIC_INIT}" ]] || [[ "${MARKLOGIC_INIT}" = "false" ]]; then
    log "MARKLOGIC_INIT is set to false or not defined, no bootstrap."
else
    err "MARKLOGIC_INIT must be true or false."
fi

################################################################
# check join cluster (eg. MARKLOGIC_JOIN_CLUSTER is set)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_JOIN_CLUSTER ]]; then
    log "MARKLOGIC_JOIN_CLUSTER is already joined, not joining cluster."
elif [[ "${MARKLOGIC_JOIN_CLUSTER}" = "true" ]]; then
    log "MARKLOGIC_JOIN_CLUSTER is true, joining cluster."
    sleep 5s
    /usr/local/bin/join-cluster.sh "${MARKLOGIC_BOOTSTRAP_HOST}" "${HOSTNAME}" "${ML_ADMIN_USERNAME}" "${ML_ADMIN_PASSWORD}"
    sudo touch /opt/MarkLogic/DOCKER_JOIN_CLUSTER
elif [ -z "${MARKLOGIC_JOIN_CLUSTER}" ] || [[ "${MARKLOGIC_JOIN_CLUSTER}" = "false" ]]; then
    log "MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster."
else
    err "MARKLOGIC_JOIN_CLUSTER must be true or false."
fi

################################################################
# tail ErrorLog for docker logs
################################################################
tail -f "${MARKLOGIC_DATA_DIR}/Logs/ErrorLog.txt"
