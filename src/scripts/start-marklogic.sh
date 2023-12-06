#! /bin/bash
###############################################################
#
#   Copyright 2023 MarkLogic Corporation.  All Rights Reserved.
#
###############################################################
#   Initialise and start MarkLogic server
#
#   ex.
#   > start-marklogic.sh
#
###############################################################

###############################################################
# Logging utility
###############################################################
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
  echo "${TIMESTAMP} ${LOG_LEVEL}: $*"
}

###############################################################
# removing MarkLogic ready file and create it when 8001 is accessible on node
###############################################################
rm -f /var/opt/MarkLogic/ready

###############################################################
# Prepare script
###############################################################
info "Starting MarkLogic container with $MARKLOGIC_VERSION from $BUILD_BRANCH"
cd ~ || exit
# Convert booleans to lowercase
for var in OVERWRITE_ML_CONF INSTALL_CONVERTERS MARKLOGIC_DEV_BUILD MARKLOGIC_INIT MARKLOGIC_JOIN_CLUSTER MARKLOGIC_JOIN_TLS_ENABLED; do
    declare $var="$(echo "${!var}" | sed -e 's/[[:blank:]]//g' | awk '{print tolower($0)}')"
done

###############################################################
# Set Hostname to the value of hostname command to /etc/marklogic.conf when MARKLOGIC_FQDN_SUFFIX is set.
###############################################################
HOST_FQDN="${HOSTNAME}"
if [[ -n "${MARKLOGIC_FQDN_SUFFIX}" ]]; then
    HOST_FQDN="$(hostname).${MARKLOGIC_FQDN_SUFFIX}"
    echo "export MARKLOGIC_HOSTNAME=\"${HOST_FQDN}\"" | sudo tee /etc/marklogic.conf
fi

################################################################
# Read in ENV values for marklogic.conf
################################################################

# If an ENV value exists in a list, append it to the /etc/marklogic.conf file
if [[ "${OVERWRITE_ML_CONF}" == "true" ]]; then
    info "OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables."
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
    [[ "${MARKLOGIC_GROUP}" ]] && echo "export MARKLOGIC_GROUP=$MARKLOGIC_GROUP" >>/etc/marklogic.conf
    [[ "${ML_HUGEPAGES_TOTAL}" ]] && echo "export ML_HUGEPAGES_TOTAL=$ML_HUGEPAGES_TOTAL" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_DISABLE_JVM}" ]] && echo "export MARKLOGIC_DISABLE_JVM=$MARKLOGIC_DISABLE_JVM" >>/etc/marklogic.conf
    [[ "${MARKLOGIC_USER}" ]] && echo "export MARKLOGIC_USER=$MARKLOGIC_USER" >>/etc/marklogic.conf
    [[ "${JAVA_HOME}" ]] && echo "export JAVA_HOME=$JAVA_HOME" >>/etc/marklogic.conf
    [[ "${CLASSPATH}" ]] && echo "export CLASSPATH=$CLASSPATH" >>/etc/marklogic.conf

    sudo chmod 400 /etc/marklogic.conf

elif [[ -z ${OVERWRITE_ML_CONF} ]] || [[ "${OVERWRITE_ML_CONF}" == "false" ]]; then
    info "OVERWRITE_ML_CONF is false, not writing to /etc/marklogic.conf"
else
    error "OVERWRITE_ML_CONF must be true or false." exit
fi

################################################################
# Install Converters if required
################################################################
if [[ "${INSTALL_CONVERTERS}" == "true" ]]; then
    if [[ -d "/opt/MarkLogic/Converters" ]]; then
        info "Converters directory: /opt/MarkLogic/Converters already exists, skipping installation of converters."
    else
        info "INSTALL_CONVERTERS is true, installing converters."
        CONVERTERS_PATH="/converters.rpm"
        sudo yum localinstall -y $CONVERTERS_PATH
    fi
elif [[ -z "${INSTALL_CONVERTERS}" ]] || [[ "${INSTALL_CONVERTERS}" == "false" ]]; then
    info "INSTALL_CONVERTERS is false, not installing converters."
else
    error "INSTALL_CONVERTERS must be true or false." exit
fi

################################################################
# Setup timezone
################################################################
if [ -n "${TZ}" ]; then
    info "TZ is defined, setting timezone to ${TZ}."
    sudo ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone
fi

# Values taken directy from documentation: https://docs.marklogic.com/guide/admin-api/cluster#id_10889
N_RETRY=5
RETRY_INTERVAL=10

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
function restart_check {
    info "Waiting for MarkLogic to restart."
    local retry_count LAST_START
    LAST_START=$(curl -s --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" "http://$1:8001/admin/v1/timestamp")
    for ((retry_count = 0; retry_count < N_RETRY; retry_count = retry_count + 1)); do
        if [ "$2" == "${LAST_START}" ] || [ -z "${LAST_START}" ]; then
            sleep ${RETRY_INTERVAL}
            LAST_START=$(curl -s --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}" "http://$1:8001/admin/v1/timestamp")
        else
            info "MarkLogic has restarted."
            return 0
        fi
    done
    error "Failed to restart $1" exit
}

################################################################
# setting default protocol and CA cert for curl calls to bootstrap host
################################################################
ML_BOOTSTRAP_PROTOCOL="http"
ML_CACERT_FILE="/run/secrets/${MARKLOGIC_JOIN_CACERT_FILE}"

################################################################
# Check if TLS is enabled on Bootstrap host
# input:  $1:     bootstrap_status
################################################################
function validate_tls_parameters {
    local bootstrap_status=$1 host_protocol
    host_protocol=$(get_host_protocol "${MARKLOGIC_BOOTSTRAP_HOST}")
    if [[ "${bootstrap_status}" == "localhost" ]]; then
        return
    fi
    if [[ "${MARKLOGIC_JOIN_TLS_ENABLED}" == "true" ]]; then
        if [[ -f "${ML_CACERT_FILE}" ]] && [[ -n "$(<"${ML_CACERT_FILE}")" ]]; then
            if [[ "${host_protocol}" == "https" ]]; then
                ML_BOOTSTRAP_PROTOCOL="https"
                # validate the CA certificate
                validate_cert "${ML_CACERT_FILE}"
                info "MARKLOGIC_JOIN_TLS_ENABLED and MARKLOGIC_JOIN_CACERT_FILE are set, TLS will be used for joining cluster."
            else
                error "TLS is not enabled on bootstrap_host_name host, please verify the configuration. Container shutting down." exit
            fi
        else
            error "MARKLOGIC_JOIN_CACERT_FILE is not set, please review the configuration. Container shutting down." exit
        fi
    elif [[ "${MARKLOGIC_JOIN_TLS_ENABLED}" == "false" ]] || [[ -z "${MARKLOGIC_JOIN_TLS_ENABLED}" ]] || [[ -v "${MARKLOGIC_JOIN_TLS_ENABLED}" ]]; then
        if [[ "${host_protocol}" == "https" ]]; then
            error "TLS is enabled on ${MARKLOGIC_BOOTSTRAP_HOST}, please verify the configuration. Container shutting down." exit
        else
            info "MARKLOGIC_JOIN_TLS_ENABLED is not set, using HTTP for joining cluster."
        fi
    else
        error "MARKLOGIC_JOIN_TLS_ENABLED must be set to true or false, please review the configuration. Container shutting down." exit
    fi
}

################################################################
# Validates certificate of a host
# input:  $1:     certificate/certificate chain
################################################################
function validate_cert {
    local cacertfile=$1
    local response
    curl -s -S -L --cacert "${cacertfile}" --ssl "${ML_BOOTSTRAP_PROTOCOL}"://"${MARKLOGIC_BOOTSTRAP_HOST}":8001 --anyauth --user "${ML_ADMIN_USERNAME}":"${ML_ADMIN_PASSWORD}"
    response=$?
    if [ $response -ne 0 ]; then
        error "MARKLOGIC_JOIN_CACERT_FILE is not valid, please check above error for details. Node shutting down." exit
    fi
}

################################################################
# curl_retry_validate(return_error, endpoint, expected_response_code, curl_options...)
# Retry a curl command until it returns the expected response
# code or fails N_RETRY times.
# Use RETRY_INTERVAL to tune the test length.
# Validate that response code is the same as expected response
# code or exit with an error.
#
#   $1 :  Flag indicating if the script should exit if the given response code is not received ("true" to exit, "false" to return the response code")
#   $2 :  The target url to test against
#   $3 :  The expected response code
#   $4+:  Additional options to pass to curl
################################################################
function curl_retry_validate {
    local retry_count response response_code response_content
    local return_error=$1; shift
    local endpoint=$1; shift
    local expected_response_code=$1; shift
    local curl_options=("$@")

    for ((retry_count = 0; retry_count < N_RETRY; retry_count = retry_count + 1)); do
        
        response=$(curl -s -m 30 -w '%{http_code}' "${curl_options[@]}" "$endpoint")
        response_code=$(tail -n1 <<< "$response")
        response_content=$(sed '$ d' <<< "$response")

        if [[ ${response_code} -eq ${expected_response_code} ]]; then
            return "${response_code}"
        else
            echo "${response_content}" > start-marklogic_curl_retry_validate.log
        fi
        
        sleep ${RETRY_INTERVAL}
    done
    if [[ "${return_error}" = "false" ]] ; then
        return "${response_code}"
    fi
    [ -f "start-marklogic_curl_retry_validate.log" ] && cat start-marklogic_curl_retry_validate.log
    error "Expected response code ${expected_response_code}, got ${response_code} from ${endpoint}." exit
}

################################################################
# Checks protocol for a host
# input:  $1:     host name
################################################################
function get_host_protocol {
    local hostname port protocol https_error_message resp
    hostname=$1
    port="${2:-8001}"
    protocol="http"
    https_error_message="You have attempted to access an HTTPS server using HTTP."
    resp=$(curl -s http://"${hostname}":"${port}")
    if [[ "${resp}" =~ ${https_error_message} ]]; then
        protocol="https"
    fi
    echo $protocol
}

################################################################
# Fetches host id
# input:  $1:     host name
################################################################
function get_host_id {
    local hostname host_id
    hostname=$1 
    host_id=""
    ML_BOOTSTRAP_PROTOCOL=$(get_host_protocol "${hostname}")
    curl_retry_validate false "${ML_BOOTSTRAP_PROTOCOL}://${hostname}:8001/admin/v1/server-config" 200 \
            "--anyauth" "--user" "${ML_ADMIN_USERNAME}:${ML_ADMIN_PASSWORD}" "-o" "host_config.xml" "-X" "GET" "-H" "Accept: application/xml" "--cacert" "${ML_CACERT_FILE}"
    [[ -f host_config.xml ]] && host_id=$(< host_config.xml grep "host-id" | sed 's%^.*<host-id.*>\(.*\)</host-id>.*$%\1%')
    echo "${host_id}"
    rm -f host_config.xml
}

################################################################
# Verifies MarkLogic bootstrap host status
# input:  $1:        MarkLogic Bootstrap Host
# returns valid:     if it's a valid MarkLogic bootstrap host
#         invalid:   if it's not a valid MarkLogic bootstrap host
#         localhost: if bootstrap host is the localhost
################################################################
function verify_bootstrap_status {
    local bootstrap_host bootstrap_host_id localhost_id
    bootstrap_host=$1
    bootstrap_host_id=$(get_host_id "${bootstrap_host}")
    localhost_id=$(get_host_id "localhost")
    if [[ "${bootstrap_host_id}" == "" ]]; then
        echo "invalid"
    elif [[ "${bootstrap_host_id}" != "" ]] && [[ "${bootstrap_host_id}" != "${localhost_id}" ]]; then
        echo "valid"
    elif [[ "${bootstrap_host_id}" != "" ]] && [[ "${bootstrap_host_id}" == "${localhost_id}" ]]; then
        echo "localhost"
    else
        error "Please verify the configuration, exiting." exit
    fi
}

################################################################
# Start MarkLogic service
################################################################
if [[ "${MARKLOGIC_DEV_BUILD}" == "true" ]]; then
    info "MARKLOGIC_DEV_BUILD is true, starting build using ${MARKLOGIC_INSTALL_DIR}/MarkLogic"
    sudo "${MARKLOGIC_INSTALL_DIR}/MarkLogic" -i . -d "${MARKLOGIC_DATA_DIR}" -p "${MARKLOGIC_PID_FILE}" &
elif [[ -z "${MARKLOGIC_DEV_BUILD}" ]] || [[ "${MARKLOGIC_DEV_BUILD}" == "false" ]]; then
    sudo /etc/init.d/MarkLogic start
else
    error "MARKLOGIC_DEV_BUILD must be true or false." exit
fi
sleep 5s

################################################################
# Extract admin credentials from a secret or env var
################################################################
SECRET_USR_FILE="/run/secrets/${MARKLOGIC_ADMIN_USERNAME_FILE}"
SECRET_PWD_FILE="/run/secrets/${MARKLOGIC_ADMIN_PASSWORD_FILE}"
SECRET_WALLET_PWD_FILE="/run/secrets/${MARKLOGIC_WALLET_PASSWORD_FILE}"

if [[ -f "${SECRET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_PWD_FILE}")" ]]; then
    info "MARKLOGIC_ADMIN_PASSWORD_FILE is set, using file as secret for admin password."
    ML_ADMIN_PASSWORD=$(<"${SECRET_PWD_FILE}")
else
    info "MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password."
    ML_ADMIN_PASSWORD="${MARKLOGIC_ADMIN_PASSWORD}"
fi

if [[ -f "${SECRET_USR_FILE}" ]] && [[ -n "$(<"${SECRET_USR_FILE}")" ]]; then
    info "MARKLOGIC_ADMIN_USERNAME_FILE is set, using file as secret for admin username."
    ML_ADMIN_USERNAME=$(<"${SECRET_USR_FILE}")
else
    info "MARKLOGIC_ADMIN_USERNAME is set, using ENV for admin username."
    ML_ADMIN_USERNAME="${MARKLOGIC_ADMIN_USERNAME}"
fi

if [[ -f "${SECRET_WALLET_PWD_FILE}" ]] && [[ -n "$(<"${SECRET_WALLET_PWD_FILE}")" ]]; then
    info "MARKLOGIC_WALLET_PASSWORD_FILE is set, using file as secret for wallet-password."
    ML_WALLET_PASSWORD=$(<"${SECRET_WALLET_PWD_FILE}")
else
    info "MARKLOGIC_WALLET_PASSWORD is set, using ENV for wallet-password."
    ML_WALLET_PASSWORD="${MARKLOGIC_WALLET_PASSWORD}"
fi

################################################################
# check marklogic init (eg. MARKLOGIC_INIT is set)
################################################################
if [[ -f /var/opt/MarkLogic/DOCKER_INIT ]]; then
    info "MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization."
elif [[ "${MARKLOGIC_INIT}" == "true" ]]; then
    info "MARKLOGIC_INIT is true, initializing the MarkLogic server."

    # Make sure username and password variables are not empty
    if [[ -z "${ML_ADMIN_USERNAME}" ]] || [[ -z "${ML_ADMIN_PASSWORD}" ]]; then
        error "MARKLOGIC_ADMIN_USERNAME and MARKLOGIC_ADMIN_PASSWORD must be set." exit
    fi
    
    ML_ADMIN_USERNAME_PAYLOAD="admin-username=${ML_ADMIN_USERNAME}"
    ML_ADMIN_PASSWORD_PAYLOAD="admin-password=${ML_ADMIN_PASSWORD}"

    # generate JSON payload conditionally with license details.
    if [[ -z "${LICENSE_KEY}" ]] || [[ -z "${LICENSEE}" ]]; then
        LICENSE_PAYLOAD="{}"
    else
        info "LICENSE_KEY and LICENSEE are defined, installing MarkLogic license."
        LICENSE_PAYLOAD="{\"license-key\" : \"${LICENSE_KEY}\",\"licensee\" : \"${LICENSEE}\"}"
    fi

    # sets realm conditionally based on user input
    if [[ -z "${REALM}" ]]; then
        ML_REALM="public"
    else
        info "REALM is defined, setting realm."
        ML_REALM="${REALM}"
    fi
    ML_REALM_PAYLOAD="realm=${ML_REALM}"
    
    if [[ -z "${ML_WALLET_PASSWORD}" ]]; then
        ML_WALLET_PASSWORD_PAYLOAD="wallet-password=${ML_ADMIN_PASSWORD}"
    else
        info "ML_WALLET_PASSWORD is defined, setting wallet-password."
        ML_WALLET_PASSWORD_PAYLOAD="wallet-password=${ML_WALLET_PASSWORD}"
    fi

    info "Initializing MarkLogic on ${HOSTNAME}"
    TIMESTAMP=$(curl --anyauth -m 30 -s --retry 5 \
        -i -X POST -H "Content-type:application/json" \
        -d "${LICENSE_PAYLOAD}" \
        http://"${HOSTNAME}":8001/admin/v1/init |
        grep "last-startup" |
        sed 's%^.*<last-startup.*>\(.*\)</last-startup>.*$%\1%')
    restart_check "${HOSTNAME}" "${TIMESTAMP}"

    # Check if bootstrap is the localhost to install security database when MARKLOGIC_JOIN_CLUSTER=true
    if [[ "${MARKLOGIC_JOIN_CLUSTER}" = "true" ]] && [[ -n "${MARKLOGIC_BOOTSTRAP_HOST}" ]]; then
        INIT_BOOTSTRAP_STATUS=$(verify_bootstrap_status "${MARKLOGIC_BOOTSTRAP_HOST}")
    fi
    # Only call /v1/instance-admin if host is bootstrap/standalone host
    # first condition is to make sure bootstrap host installs security db even when MARKLOGIC_JOIN_CLUSTER is true
    # second condition is for request where MARKLOGIC_JOIN_CLUSTER is not true, considering it's a bootstrap host
    if [[ "${INIT_BOOTSTRAP_STATUS}" == "localhost" ]] || [[ "${MARKLOGIC_JOIN_CLUSTER}" != "true" ]]; then
        info "Installing admin username and password, and initialize the security database and objects."

        # Check TLS parameters to log expected messages
        if [[ "${MARKLOGIC_JOIN_TLS_ENABLED}" == "true" ]] || [[ -n "${MARKLOGIC_JOIN_CACERT_FILE}" ]]; then
            info "MARKLOGIC_JOIN_TLS_ENABLED/MARKLOGIC_JOIN_CACERT_FILE are ignored for Bootstrap host conguration."
        fi

        # Get last restart timestamp directly before instance-admin call to verify restart after
        TIMESTAMP=$(curl -s --anyauth "http://${HOSTNAME}:8001/admin/v1/timestamp")

        curl_retry_validate true "http://${HOSTNAME}:8001/admin/v1/instance-admin" 202 \
            "-o" "/dev/null" "-X" "POST" "-H" "Content-type:application/x-www-form-urlencoded; charset=utf-8" "-d" "${ML_ADMIN_USERNAME_PAYLOAD}" "--data-urlencode" "${ML_ADMIN_PASSWORD_PAYLOAD}" "-d" "${ML_REALM_PAYLOAD}" "--data-urlencode" "${ML_WALLET_PASSWORD_PAYLOAD}"

        restart_check "${HOSTNAME}" "${TIMESTAMP}"
    fi

    sudo touch /var/opt/MarkLogic/DOCKER_INIT
elif [[ -z "${MARKLOGIC_INIT}" ]] || [[ "${MARKLOGIC_INIT}" == "false" ]]; then
    info "MARKLOGIC_INIT is set to false or not defined, not initializing."
else
    error "MARKLOGIC_INIT must be true or false." exit
fi

################################################################
# check join cluster (eg. MARKLOGIC_JOIN_CLUSTER is set and host is not bootstrap host)
################################################################
if [[ -f /var/opt/MarkLogic/DOCKER_JOIN_CLUSTER ]]; then
    info "MARKLOGIC_JOIN_CLUSTER is true, but skipping join because this instance has already joined a cluster."
elif [[ "${MARKLOGIC_JOIN_CLUSTER}" == "true" ]]; then
    # Check if TLS is enabled on Bootstrap host
    # Using INIT_BOOTSTRAP_STATUS to verify if it's not localhost
    validate_tls_parameters "${INIT_BOOTSTRAP_STATUS}"

    # Validate bootsrap host before joining cluster
    BOOTSTRAP_STATUS=$(verify_bootstrap_status "${MARKLOGIC_BOOTSTRAP_HOST}")

    if [[ "${BOOTSTRAP_STATUS}" == "valid" ]]; then
        info "MARKLOGIC_JOIN_CLUSTER is true and join conditions are met, joining host to the cluster."
        if [[ -z "${MARKLOGIC_GROUP}" ]]; then
            info "MARKLOGIC_GROUP is not specified, adding host to the Default group."
            MARKLOGIC_GROUP_PAYLOAD="group=Default"
        else
            curl_retry_validate false "${ML_BOOTSTRAP_PROTOCOL}://${MARKLOGIC_BOOTSTRAP_HOST}:8002/manage/v2/groups/${MARKLOGIC_GROUP}" 200 \
                "-X" "GET" "-o" "/dev/null" "--anyauth" "--user" "${ML_ADMIN_USERNAME}:${ML_ADMIN_PASSWORD}" "--cacert" "${ML_CACERT_FILE}"
            GROUP_RESP_CODE=$?
            if [[ ${GROUP_RESP_CODE} -eq 200 ]]; then
                info "MARKLOGIC_GROUP is specified, adding host to the ${MARKLOGIC_GROUP} group."
                MARKLOGIC_GROUP_PAYLOAD="group=${MARKLOGIC_GROUP}"
            else
                error "MARKLOGIC_GROUP ${MARKLOGIC_GROUP} does not exist on the cluster" exit
            fi
        fi
        curl_retry_validate true "http://${HOSTNAME}:8001/admin/v1/server-config" 200 \
            "--anyauth" "--user" "${ML_ADMIN_USERNAME}:${ML_ADMIN_PASSWORD}" "-o" "host.xml" "-X" "GET" "-H" "Accept: application/xml"

        curl_retry_validate true "${ML_BOOTSTRAP_PROTOCOL}://${MARKLOGIC_BOOTSTRAP_HOST}:8001/admin/v1/cluster-config" 200 \
            "--anyauth" "--user" "${ML_ADMIN_USERNAME}:${ML_ADMIN_PASSWORD}" "-X" "POST" "-d" "${MARKLOGIC_GROUP_PAYLOAD}" "--data-urlencode" "server-config@./host.xml" "-H" "Content-type: application/x-www-form-urlencoded" "-o" "cluster.zip" "--cacert" "${ML_CACERT_FILE}"

        # Get last restart timestamp directly before cluster-config call to verify restart after
        TIMESTAMP=$(curl -s --anyauth "http://${HOSTNAME}:8001/admin/v1/timestamp")

        curl_retry_validate true "http://${HOSTNAME}:8001/admin/v1/cluster-config" 202 \
            "-o" "/dev/null" "--anyauth" "--user" "${ML_ADMIN_USERNAME}:${ML_ADMIN_PASSWORD}" "-X" "POST" "-H" "Content-type: application/zip" "--data-binary" "@./cluster.zip"
    
        restart_check "${HOSTNAME}" "${TIMESTAMP}"

        rm -f host.xml
        rm -f cluster.zip
        sudo touch /var/opt/MarkLogic/DOCKER_JOIN_CLUSTER
    elif [[ "${BOOTSTRAP_STATUS}" == "localhost" ]]; then
        info "HOST cannot join itself, skipped joining cluster."
    else
        error "Bootstrap host $MARKLOGIC_BOOTSTRAP_HOST not found. Please verify the configuration, exiting." exit
    fi
elif [[ -z "${MARKLOGIC_JOIN_CLUSTER}" ]] || [[ "${MARKLOGIC_JOIN_CLUSTER}" == "false" ]]; then
    info "MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster."
else
    error "MARKLOGIC_JOIN_CLUSTER must be true or false." exit
fi

################################################################
# check if node is available and mark it ready
################################################################

# use latest health check only for version 11 and up
if [[ "${MARKLOGIC_VERSION}" =~ "10" ]] || [[ "${MARKLOGIC_VERSION}" =~ "9" ]]; then
    HEALTH_CHECK="7997"
else 
     HEALTH_CHECK="7997/LATEST/healthcheck"
fi
ML_HOST_PROTOCOL=$(get_host_protocol "localhost" "7997")

while true
do
    HOST_RESP_CODE=$(curl "${ML_HOST_PROTOCOL}"://"${HOSTNAME}":"${HEALTH_CHECK}" -X GET -o host_health.xml -s -w "%{http_code}\n" --cacert "${ML_CACERT_FILE}")
    [[ -f host_health.xml ]] && error_message=$(< host_health.xml grep "SEC-DEFAULTUSERDNE")
    if [[ "${MARKLOGIC_INIT}" == "true" ]] && [ "${HOST_RESP_CODE}" -eq 200 ]; then
        sudo touch /var/opt/MarkLogic/ready
        info "Cluster config complete, marking this container as ready."
        break
    elif [[ "${MARKLOGIC_INIT}" == "false" ]] && [[ "${error_message}" =~ "SEC-DEFAULTUSERDNE" ]]; then
        sudo touch /var/opt/MarkLogic/ready
        info "Cluster config complete, marking this container as ready."
        rm -f host_health.xml
        break
    else
        info "MarkLogic not ready yet, retrying."
        sleep 5
    fi
done

################################################################
# tail /dev/null to keep container active
################################################################
tail -f /dev/null
