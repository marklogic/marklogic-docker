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
if [[ "${OVERWRITE_ML_CONF}" == "true" ]]; then
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

elif [[ -z ${OVERWRITE_ML_CONF} ]] || [[ "${OVERWRITE_ML_CONF}" == "false" ]]; then
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
elif [[ -z "${INSTALL_CONVERTERS}" ]] || [[ "${INSTALL_CONVERTERS}" == "false" ]]; then
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
# restart_check(hostname, baseline_timestamp, caller_lineno)
#
# Use the timestamp service to detect a server restart, given a
# a baseline timestamp. Use N_RETRY and RETRY_INTERVAL to tune
# the test length. Include authentication in the curl command
# so the function works whether or not security is initialized.
#   $1 :  The hostname to test against
#   $2 :  The baseline timestamp
#   $3 :  Invokers LINENO, for improved error reporting
# Returns 0 if restart is detected, exits with an error if not.
################################################################
N_RETRY=5 # 5 and 10 numbers taken directy from documentation: https://docs.marklogic.com/guide/admin-api/cluster#id_10889
RETRY_INTERVAL=10

function restart_check {
    LAST_START=$(curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" -s "http://$1:8001/admin/v1/timestamp")
    for i in $(seq 1 ${N_RETRY}); do
        if [ "$2" == "$LAST_START" ] || [ "$LAST_START" == "" ]; then
            sleep ${RETRY_INTERVAL}
            LAST_START=$(curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" -s "http://$1:8001/admin/v1/timestamp")
        else
            return 0
        fi
    done
    echo "ERROR: Line $3: Failed to restart $1"
    exit 1
}

################################################################
# response_code_validation(response_code, expected_response_code)
#
# validate that the response code is what we expect it to be
#   $1 :  Actual response code
#   $2 :  Expected response code
################################################################
function response_code_validation {
    if [[ "$1" -ne "$2" ]]; then
        log "Expected response code $2, got $1"
        exit 1
    fi
}

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
# check marklogic init (eg. MARKLOGIC_INIT is set)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_INIT ]]; then
    log "MARKLOGIC_INIT is already initialized."
elif [[ "${MARKLOGIC_INIT}" == "true" ]]; then
    log "MARKLOGIC_INIT is true, initialzing."

    # generate JSON payload conditionally with license details.
    if [[ -z "${LICENSE_KEY}" ]] || [[ -z "${LICENSEE}" ]]; then
        LICENSE_PAYLOAD="{}"
    else
        log "LICENSE_KEY and LICENSEE are defined, generating license payload."
        LICENSE_PAYLOAD="{\"license-key\" : \"${LICENSE_KEY}\",\"licensee\" : \"${LICENSEE}\"}"
    fi

    log "Initialzing MarkLogic on ${HOSTNAME}."
    TIMESTAMP=$(curl --anyauth -m 20 -s --retry 8 --retry-all-errors -f \
        -i -X POST -H "Content-type:application/json" \
        -d "${LICENSE_PAYLOAD}" \
        http://"${HOSTNAME}":8001/admin/v1/init \
        | grep "last-startup" \
        | sed 's%^.*<last-startup.*>\(.*\)</last-startup>.*$%\1%')

    # Make sure marklogic has shut down and come back up before moving on
    restart_check "${HOSTNAME}" "${TIMESTAMP}" 

    res_code=$(curl -s -m 20 --retry 8 --retry-all-errors -f \
        -X POST -H "Content-type: application/x-www-form-urlencoded" \
        --data "admin-username=${ML_ADMIN_USERNAME}" --data "admin-password=${ML_ADMIN_PASSWORD}" \
        --data "realm=public" \
        http://"${HOSTNAME}":8001/admin/v1/instance-admin)

    response_code_validation "${res_code}" 200

    sudo touch /opt/MarkLogic/DOCKER_INIT
elif [[ -z "${MARKLOGIC_INIT}" ]] || [[ "${MARKLOGIC_INIT}" == "false" ]]; then
    log "MARKLOGIC_INIT is set to false or not defined, not initialzing."
else
    err "MARKLOGIC_INIT must be true or false."
fi

################################################################
# check join cluster (eg. MARKLOGIC_JOIN_CLUSTER is set and host is not bootstrap host)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_JOIN_CLUSTER ]]; then
    log "MARKLOGIC_JOIN_CLUSTER is already joined, not joining cluster."
elif [[ "${MARKLOGIC_JOIN_CLUSTER}" == "true" ]] && [[ "${HOSTNAME}" != "${MARKLOGIC_BOOTSTRAP_HOST}" ]]; then
    log "Join conditions met, Joining cluster."

    res_code=$(curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" \
        -w %{http_code} -s \
        -m 20 --retry 8 --retry-all-errors -f \
        -o host.xml -X GET -H "Accept: application/xml" \
        http://"${HOSTNAME}":8001/admin/v1/server-config)
    
    response_code_validation "${res_code}" 200

    res_code=$(curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" \
        -w %{http_code} -s \
        -m 20 --retry 8 --retry-all-errors -f \
        -X POST -d "group=Default" \
        --data-urlencode "server-config@./host.xml" \
        -H "Content-type: application/x-www-form-urlencoded" \
        -o cluster.zip \
        http://"${MARKLOGIC_BOOTSTRAP_HOST}":8001/admin/v1/cluster-config)
    
    response_code_validation "${res_code}" 200

    res_code=$(curl --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" \
        -o /dev/null -w %{http_code} -s \
        -m 20 --retry 8 --retry-all-errors -f \
        -X POST -H "Content-type: application/zip" \
        --data-binary @./cluster.zip \
        http://"${HOSTNAME}":8001/admin/v1/cluster-config)
    
    response_code_validation "${res_code}" 202

    rm -f host.xml
    rm -f cluster.zip
    sudo touch /opt/MarkLogic/DOCKER_JOIN_CLUSTER
elif [[ -z "${MARKLOGIC_JOIN_CLUSTER}" ]] || [[ "${MARKLOGIC_JOIN_CLUSTER}" == "false" ]] || [[ "${HOSTNAME}" == "${MARKLOGIC_BOOTSTRAP_HOST}" ]]; then
    log "MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster."
else
    err "MARKLOGIC_JOIN_CLUSTER must be true or false."
fi

################################################################
# mark the node ready
################################################################
log "Cluster config complete, marking node as ready"
sudo touch /var/opt/MarkLogic/ready

################################################################
# tail ErrorLog for docker logs
################################################################
tail -f "${MARKLOGIC_DATA_DIR}/Logs/ErrorLog.txt"
