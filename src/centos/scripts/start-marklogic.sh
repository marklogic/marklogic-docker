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
# Set Hostname to the value of hostname command to /etc/marklogic.conf when MARKLOGIC_FQDN_SUFFIX is set.
###############################################################
if [[ -n "${MARKLOGIC_FQDN_SUFFIX}" ]]; then
    HOST_FQDN="$(hostname).${MARKLOGIC_FQDN_SUFFIX}"
    echo "export MARKLOGIC_HOSTNAME=\"${HOST_FQDN}\"" | sudo tee /etc/marklogic.conf
fi

###############################################################
# Prepare script
###############################################################
cd ~ || exit
# Convert booleans to lowercase
for var in OVERWRITE_ML_CONF INSTALL_CONVERTERS MARKLOGIC_DEV_BUILD MARKLOGIC_INIT MARKLOGIC_JOIN_CLUSTER; do
    declare $var="$(echo "${!var}" | sed -e 's/[[:blank:]]//g' | awk '{print tolower($0)}')"
done

#log utility
info() {
    log "Info" "$@"
}
error() {
    log "Error" "$1"
    local EXIT_STATUS="$2"
    if [[ ${EXIT_STATUS} == "exit" ]]
    then
    exit 1
    fi
}
log () {
  local LOG_LEVEL=${1}
  TIMESTAMP=$(date +"%Y-%m-%d %T.%3N")
  shift
  echo "${TIMESTAMP} ${LOG_LEVEL}: $@"
}

################################################################
# Read in ENV values for marklogic.conf
################################################################

# If an ENV value exists in a list, append it to the /etc/marklogic.conf file
if [[ "${OVERWRITE_ML_CONF}" == "true" ]]; then
    info "Deleting previous /etc/marklogic.conf, if it exists, and overwriting with env variables."
    rm -f /etc/marklogic.conf
    sudo touch /etc/marklogic.conf && sudo chmod 777 /etc/marklogic.conf

    [[ "${MARKLOGIC_PID_FILE}" ]] && echo "export MARKLOGIC_PID_FILE=$MARKLOGIC_PID_FILE" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_UMASK}" ]] && echo "export MARKLOGIC_UMASK=$MARKLOGIC_UMASK" >>/etc/marklogic.conf
    [[ "${TZ}" ]] && echo "export TZ=$TZ " >>/etc/marklogic.conf
    [[ "${MARKLOGIC_ADMIN_USERNAME}" ]] && echo "export MARKLOGIC_ADMIN_USERNAME=$MARKLOGIC_ADMIN_USERNAME" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_ADMIN_PASSWORD}" ]] && echo "export MARKLOGIC_ADMIN_PASSWORD=$MARKLOGIC_ADMIN_PASSWORD" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_WALLET_PASSWORD}" ]] && echo "export MARKLOGIC_WALLET_PASSWORD=$MARKLOGIC_WALLET_PASSWORD" >>/etc/marklogic.conf
    [[ "${REALM}" ]] && echo "export REALM=$REALM" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_LICENSEE}" ]] && echo "export MARKLOGIC_LICENSEE=$MARKLOGIC_LICENSEE" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_LICENSE_KEY}" ]] && echo "export MARKLOGIC_LICENSE_KEY=$MARKLOGIC_LICENSE_KEY" >>/etc/marklogic.conf
    [[ "${ML_HUGEPAGES_TOTAL}" ]] && echo "export ML_HUGEPAGES_TOTAL=$ML_HUGEPAGES_TOTAL" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_DISABLE_JVM}" ]] && echo "export MARKLOGIC_DISABLE_JVM=$MARKLOGIC_DISABLE_JVM" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_USER}" ]] && echo "export MARKLOGIC_USER=$MARKLOGIC_USER" >>/etc/marklogic.conf
    [[ "${JAVA_HOME}" ]] && echo "export JAVA_HOME=$JAVA_HOME" >>/etc/marklogic.conf
    [[ "${CLASSPATH}" ]] && echo "export CLASSPATH=$CLASSPATH" >>/etc/marklogic.conf

    sudo chmod 400 /etc/marklogic.conf

elif [[ -z ${OVERWRITE_ML_CONF} ]] || [[ "${OVERWRITE_ML_CONF}" == "false" ]]; then
    info "Not writing to /etc/marklogic.conf"
else
    error "OVERWRITE_ML_CONF must be true or false." exit
fi

################################################################
# Install Converters if required
################################################################
if [[ "${INSTALL_CONVERTERS}" == "true" ]]; then
    if [[ -d "/opt/MarkLogic/Converters" ]]; then
        info "Converters directory: /opt/MarkLogic/Converters already exists, skipping installation."
    else
        info "Installing Converters"
        CONVERTERS_PATH="/converters.rpm"
        sudo yum localinstall -y $CONVERTERS_PATH
    fi
elif [[ -z "${INSTALL_CONVERTERS}" ]] || [[ "${INSTALL_CONVERTERS}" == "false" ]]; then
    info "Not Installing Converters"
else
    error "INSTALL_CONVERTERS must be true or false." exit
fi

################################################################
# Setup timezone
################################################################
if [ -n "${TZ}" ]; then
    info "Setting timezone to ${TZ}"
    sudo ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone
fi

################################################################
# Start MarkLogic service
################################################################
if [[ "${MARKLOGIC_DEV_BUILD}" == "true" ]]; then
    info "MARKLOGIC_DEV_BUILD is true, starting using ${MARKLOGIC_INSTALL_DIR}/MarkLogic"
    sudo "${MARKLOGIC_INSTALL_DIR}/MarkLogic" -i . -d "${MARKLOGIC_DATA_DIR}" -p "${MARKLOGIC_PID_FILE}" &
elif [[ -z "${MARKLOGIC_DEV_BUILD}" ]] || [[ "${MARKLOGIC_DEV_BUILD}" == "false" ]]; then
    sudo service MarkLogic start
else
    error "MARKLOGIC_DEV_BUILD must be true or false." exit
fi
sleep 5s

################################################################
# Check if admin password is a secret or env var
################################################################
SECRET_USR_FILE="/run/secrets/${MARKLOGIC_ADMIN_USERNAME_FILE}"
SECRET_PWD_FILE="/run/secrets/${MARKLOGIC_ADMIN_PASSWORD_FILE}"
SECRET_WALLET_PWD_FILE="/run/secrets/${MARKLOGIC_WALLET_PASSWORD_FILE}"

if [[ -f "${SECRET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_PWD_FILE}")" ]]; then
    info "Using docker secrets for credentials."
    ML_ADMIN_PASSWORD=$(<"$SECRET_PWD_FILE")
else
    info "Using ENV for credentials."
    ML_ADMIN_PASSWORD="${MARKLOGIC_ADMIN_PASSWORD}"
fi

if [[ -f "$SECRET_USR_FILE" ]] && [[ -n "$(<"$SECRET_USR_FILE")" ]]; then
    info "Using docker secrets for credentials."
    ML_ADMIN_USERNAME=$(<"$SECRET_USR_FILE")
else
    info "Using ENV for credentials."
    ML_ADMIN_USERNAME="${MARKLOGIC_ADMIN_USERNAME}"
fi

if [[ -f "$SECRET_WALLET_PWD_FILE" ]] && [[ -n "$(<"$SECRET_WALLET_PWD_FILE")" ]]; then
    info "Using docker secret for wallet-password."
    ML_WALLET_PASSWORD=$(<"$SECRET_WALLET_PWD_FILE")
else
    info "Using ENV for wallet-password."
    ML_WALLET_PASSWORD="${MARKLOGIC_WALLET_PASSWORD}"
fi

################################################################
# check marklogic init (eg. MARKLOGIC_INIT is set)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_INIT ]]; then
    info "MARKLOGIC_INIT is already initialized."
elif [[ "${MARKLOGIC_INIT}" == "true" ]]; then
    info "MARKLOGIC_INIT is true, initialzing."

    # generate JSON payload conditionally with license details.
    if [[ -z "${LICENSE_KEY}" ]] || [[ -z "${LICENSEE}" ]]; then
        LICENSE_PAYLOAD="{}"
    else
        info "LICENSE_KEY and LICENSEE are defined, generating license payload."
        LICENSE_PAYLOAD="{\"license-key\" : \"${LICENSE_KEY}\",\"licensee\" : \"${LICENSEE}\"}"
    fi

    # sets realm conditionally based on user input
    if [[ -z "${REALM}" ]]; then
        ML_REALM="public"
    else
        info "REALM is defined, setting realm"
        ML_REALM="${REALM}"
    fi

    if [[ -z "${ML_WALLET_PASSWORD}" ]]; then
        ML_WALLET_PASSWORD_PAYLOAD=""
    else
        info "ML_WALLET_PASSWORD is defined, setting wallet password."
        ML_WALLET_PASSWORD_PAYLOAD="wallet-password=${ML_WALLET_PASSWORD}"
    fi

    info "Initialzing MarkLogic on ${HOSTNAME}."

    curl -s --anyauth -i -X POST \
        -H "Content-type:application/json" \
        -d "${LICENSE_PAYLOAD}" \
        "http://${HOSTNAME}:8001/admin/v1/init"
    sleep 5s
    curl -s -X POST -H "Content-type: application/x-www-form-urlencoded" \
        --data "admin-username=${ML_ADMIN_USERNAME}" --data "admin-password=${ML_ADMIN_PASSWORD}" \
        --data "realm=${ML_REALM}" --data "${ML_WALLET_PASSWORD_PAYLOAD}" \
        "http://${HOSTNAME}:8001/admin/v1/instance-admin"
    sleep 5s
    sudo touch /opt/MarkLogic/DOCKER_INIT
elif [[ -z "${MARKLOGIC_INIT}" ]] || [[ "${MARKLOGIC_INIT}" == "false" ]]; then
    info "MARKLOGIC_INIT is set to false or not defined, not initialzing."
else
    error "MARKLOGIC_INIT must be true or false." exit
fi

################################################################
# check join cluster (eg. MARKLOGIC_JOIN_CLUSTER is set and host is not bootstrap host)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_JOIN_CLUSTER ]]; then
    info "MARKLOGIC_JOIN_CLUSTER is already joined, not joining cluster."
elif [[ "${MARKLOGIC_JOIN_CLUSTER}" == "true" ]] && [[ "${HOSTNAME}" != "${MARKLOGIC_BOOTSTRAP_HOST}" ]]; then
    info "Join conditions met, Joining cluster."
    sleep 5s
    cluster="${MARKLOGIC_BOOTSTRAP_HOST}"
    curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" -m 20 -s -o host.xml -X GET -H "Accept: application/xml" http://"${joiner}":8001/admin/v1/server-config
    curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" -m 20 -s -X POST -d "group=Default" --data-urlencode "server-config@./host.xml" -H "Content-type: application/x-www-form-urlencoded" -o cluster.zip http://"${cluster}":8001/admin/v1/cluster-config

    sleep 10s

    curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" -m 20 -s -X POST -H "Content-type: application/zip" --data-binary @./cluster.zip http://"${joiner}":8001/admin/v1/cluster-config
    sleep 5s

    rm -f host.xml
    rm -f cluster.zip
    sudo touch /opt/MarkLogic/DOCKER_JOIN_CLUSTER
elif [[ -z "${MARKLOGIC_JOIN_CLUSTER}" ]] || [[ "${MARKLOGIC_JOIN_CLUSTER}" == "false" ]] || [[ "${HOSTNAME}" == "${MARKLOGIC_BOOTSTRAP_HOST}" ]]; then
    info "MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster."
else
    error "MARKLOGIC_JOIN_CLUSTER must be true or false." exit
fi

################################################################
# mark the node ready
################################################################
info "Cluster config complete, marking node as ready"
sudo touch /var/opt/MarkLogic/ready

################################################################
# tail ErrorLog for docker logs
################################################################
tail -f "${MARKLOGIC_DATA_DIR}/Logs/ErrorLog.txt"
