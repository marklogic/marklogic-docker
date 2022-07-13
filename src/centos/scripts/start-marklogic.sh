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

###############################################################
# Define log and err functions
###############################################################
log() {
    echo "$(basename "${0}"): ${*}"
}
err() {
    echo "$(basename "${0}") ERROR: ${*}" >&2
    exit 1
}

###############################################################
# Set Hostname to the value of hostname command to /etc/marklogic.conf when MARKLOGIC_FQDN_SUFFIX is set.
###############################################################
if [[ -n "${MARKLOGIC_FQDN_SUFFIX}" ]]; then
    HOST_FQDN="$(hostname).${MARKLOGIC_FQDN_SUFFIX}"
    echo "export MARKLOGIC_HOSTNAME=\"${HOST_FQDN}\"" | sudo tee /etc/marklogic.conf
fi

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
# restart_check(hostname, baseline_timestamp)
#
# Use the timestamp service to detect a server restart, given a
# a baseline timestamp. Use N_RETRY and RETRY_INTERVAL to tune
# the test length. Include authentication in the curl command
# so the function works whether or not security is initialized.
#   $1 :  The hostname to test against
#   $2 :  The baseline timestamp
# Returns 0 if restart is detected, exits with an error if not.
################################################################
N_RETRY=5 # 5 and 10 numbers taken directy from documentation: https://docs.marklogic.com/guide/admin-api/cluster#id_10889
RETRY_INTERVAL=10

function restart_check {
    LAST_START=$(curl -s --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" "http://$1:8001/admin/v1/timestamp")
    for i in $(seq 1 ${N_RETRY}); do
        if [ "$2" == "${LAST_START}" ] || [ -z "${LAST_START}" ]; then
            sleep ${RETRY_INTERVAL}
            LAST_START=$(curl -s --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" "http://$1:8001/admin/v1/timestamp")
        else
            log "MarkLogic has restarted."
            return 0
        fi
    done
    err "Failed to restart $1"
}

################################################################
# retry_and_timeout(target_url, expected_response_code, additional_options)
# The third argument is optional and can be used to pass additional options to curl.
# Retry a curl command until it returns the expected response
# code or fails N_RETRY times.
# Use RETRY_INTERVAL to tune the test length.
# Validate that response code is the same as expected response
# code or exit with an error.
#
#   $1 :  The target url to test against
#   $2 :  The expected response code
#   $3 :  Additional options to pass to curl
################################################################
function curl_retry_validate {
    for ((i = 0; i < N_RETRY; i = i + 1)); do
        request="curl -m 30 -s -w '%{http_code}' $3 $1"
        response_code=$(eval "${request}")
        if [[ ${response_code} -eq $2 ]]; then
            return 0
        fi
        sleep ${RETRY_INTERVAL}
    done

    err "Expected response code ${2}, got ${response_code} from ${1}."
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
SECRET_WALLET_PWD_FILE="/run/secrets/${MARKLOGIC_WALLET_PASSWORD_FILE}"

if [[ -f "${SECRET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_PWD_FILE}")" ]]; then
    log "Using Docker secrets for credentials."
    ML_ADMIN_PASSWORD=$(<"${SECRET_PWD_FILE}")
else
    log "Using ENV for credentials."
    ML_ADMIN_PASSWORD="${MARKLOGIC_ADMIN_PASSWORD}"
fi

if [[ -f "${SECRET_USR_FILE}" ]] && [[ -n "$(<"${SECRET_USR_FILE}")" ]]; then
    log "Using Docker secrets for credentials."
    ML_ADMIN_USERNAME=$(<"${SECRET_USR_FILE}")
else
    log "Using ENV for credentials."
    ML_ADMIN_USERNAME="${MARKLOGIC_ADMIN_USERNAME}"
fi

if [[ -f "${SECRET_WALLET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_WALLET_PWD_FILE}")" ]]; then
    log "Using Docker secret for wallet-password."
    ML_WALLET_PASSWORD=$(<"${SECRET_WALLET_PWD_FILE}")
else
    log "Using ENV for wallet-password."
    ML_WALLET_PASSWORD="${MARKLOGIC_WALLET_PASSWORD}"
fi

################################################################
# check marklogic init (eg. MARKLOGIC_INIT is set)
################################################################
if [[ -f /opt/MarkLogic/DOCKER_INIT ]]; then
    log "MARKLOGIC_INIT is already initialized."
elif [[ "${MARKLOGIC_INIT}" == "true" ]]; then
    log "MARKLOGIC_INIT is true, initialzing."

    # Make sure username and password variables are not empty
    if [[ -z "${ML_ADMIN_USERNAME}" ]] || [[ -z "${ML_ADMIN_PASSWORD}" ]]; then
        err "ML_ADMIN_USERNAME and ML_ADMIN_PASSWORD must be set."
    fi

    # generate JSON payload conditionally with license details.
    if [[ -z "${LICENSE_KEY}" ]] || [[ -z "${LICENSEE}" ]]; then
        LICENSE_PAYLOAD="{}"
    else
        log "LICENSE_KEY and LICENSEE are defined, generating license payload."
        LICENSE_PAYLOAD="{\"license-key\" : \"${LICENSE_KEY}\",\"licensee\" : \"${LICENSEE}\"}"
    fi

    # sets realm conditionally based on user input
    if [[ -z "${REALM}" ]]; then
        ML_REALM="public"
    else
        log "REALM is defined, setting realm"
        ML_REALM="${REALM}"
    fi

    if [[ -z "${ML_WALLET_PASSWORD}" ]]; then
        ML_WALLET_PASSWORD_PAYLOAD=""
    else
        log "ML_WALLET_PASSWORD is defined, setting wallet-password."
        ML_WALLET_PASSWORD_PAYLOAD="wallet-password=${ML_WALLET_PASSWORD}"
    fi

    log "Initialzing MarkLogic on ${HOSTNAME}."
    TIMESTAMP=$(curl --anyauth -m 30 -s --retry 5 \
        -i -X POST -H "Content-type:application/json" \
        -d "${LICENSE_PAYLOAD}" \
        http://"${HOSTNAME}":8001/admin/v1/init |
        grep "last-startup" |
        sed 's%^.*<last-startup.*>\(.*\)</last-startup>.*$%\1%')

    # Make sure marklogic has shut down and come back up before moving on
    log "Waiting for MarkLogic to restart."

    restart_check "${HOSTNAME}" "${TIMESTAMP}"

    curl_retry_validate "http://${HOSTNAME}:8001/admin/v1/instance-admin" 202 "-o /dev/null \
        -X POST -H \"Content-type:application/x-www-form-urlencoded\" \
        -d \"admin-username=${ML_ADMIN_USERNAME}\" -d \"admin-password=${ML_ADMIN_PASSWORD}\" \
        -d \"realm=${ML_REALM}\" -d \"${ML_WALLET_PASSWORD_PAYLOAD}\""

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

    curl_retry_validate "http://${HOSTNAME}:8001/admin/v1/server-config" 200 "--anyauth --user \"${ML_ADMIN_USERNAME}\":\"${ML_ADMIN_PASSWORD}\" \
        -o host.xml -X GET -H \"Accept: application/xml\""

    curl_retry_validate "http://${MARKLOGIC_BOOTSTRAP_HOST}:8001/admin/v1/cluster-config" 200 "--anyauth --user \"${ML_ADMIN_USERNAME}\":\"${ML_ADMIN_PASSWORD}\" \
        -X POST -d \"group=Default\" \
        --data-urlencode \"server-config@./host.xml\" \
        -H \"Content-type: application/x-www-form-urlencoded\" \
        -o cluster.zip"

    curl_retry_validate "http://${HOSTNAME}:8001/admin/v1/cluster-config" 202 "-o /dev/null --anyauth --user \"${ML_ADMIN_USERNAME}\":\"${ML_ADMIN_PASSWORD}\" \
         -X POST -H \"Content-type: application/zip\" \
        --data-binary @./cluster.zip"

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
