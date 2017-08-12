#!/bin/bash

set -x

# $1 peer config file name
function extract_peer_hosts {
  local HOSTNAMES=$(awk -F: '{print $1}' < /etc/$1/conf/$1-hostnames | sort | uniq)
  echo $HOSTNAMES
}

# $1 hostname
# $2 peer config file name
# $3 parameter name
function extract_peer_config_value {
  ROWS=$(cat /etc/$2/conf/$2-hostnames | grep $1)
  while read -r line; do
    NAME_VALUE=$(echo $line | awk -F: '{print $2}')
    NAME=$(echo $NAME_VALUE | awk -F= '{print $1}')
    local VALUE=$(echo $NAME_VALUE | awk -F= '{print $2}')
    if [[ "$NAME" == "$3" ]]; then
      echo $VALUE
      return 0
    fi
  done <<< "$ROWS"
}

# Example first line of version file: version=0.1.0
PARROT_MANAGER_VERSION=$(grep "^version=" $PARROT_MANAGER_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Parrot Manager version found: ${PARROT_MANAGER_VERSION}"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT MANAGER"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# COMMAND:                 $1"
echo -e "# SERVICE:                 $2"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                    `date`"
echo -e "# PORT:                    $PORT"
echo -e "# CONF_PORT:               $CONF_PORT"
echo -e "# HOST:                    $HOST"
echo -e "# CONF_DIR:                $CONF_DIR"
echo -e "# PARROT_MANAGER_HOME:     $PARROT_MANAGER_HOME"
echo -e "# PARROT_MANAGER_VERSION:  $PARROT_MANAGER_VERSION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:             $SSL_ENABLED"
echo -e "# SSL_PORT:                $SSL_PORT"
echo -e "# TLS_EMAIL:               $TLS_EMAIL"
echo -e "######################################################################################"

export LOG_FILE_NAME=$2
export HOME_UI=$CONF_DIR/$2

if [[ "$2" == "kafka-topics-ui" ]]; then
  HOSTNAMES=$(extract_peer_hosts "kafka-rest")
  HOSTNAME=(${HOSTNAMES[@]})
  KAFKA_REST_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "kafka-rest" "ssl.enabled")
  KAFKA_REST_SSL_PORT=$(extract_peer_config_value $HOSTNAME "kafka-rest" "ssl.port")
  KAFKA_REST_PORT=$(extract_peer_config_value $HOSTNAME "kafka-rest" "port")
  if [[ "$KAFKA_REST_SSL_ENABLED" == "true" ]]; then
    export KAFKA_REST_PROXY_URL="https://$HOSTNAME:$KAFKA_REST_SSL_PORT"
  else
    export KAFKA_REST_PROXY_URL="http://$HOSTNAME:$KAFKA_REST_PORT"
  fi
elif [[ "$2" == "kafka-connect-ui" ]]; then
  HOSTNAMES=$(extract_peer_hosts "parrot-stream")
  CONNECT_URL=""
  while read -r host; do
    PARROT_STREAM_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "parrot-stream" "ssl.enabled")
    PARROT_STREAM_REST_PORT=$(extract_peer_config_value $HOSTNAME "parrot-stream" "rest.port")
    if [[ "$PARROT_STREAM_SSL_ENABLED" == "true" ]]; then
      CONNECT_URL="$CONNECT_URL,https://$host:$PARROT_STREAM_REST_PORT"
    else
      CONNECT_URL="$CONNECT_URL,http://$host:$PARROT_STREAM_REST_PORT"
    fi
  done <<< "$HOSTNAMES"
  export CONNECT_URL=${CONNECT_URL#","}
elif [[ "$2" == "schema-registry-ui" ]]; then
  HOSTNAMES=$(extract_peer_hosts "schema-registry")
  HOSTNAME=(${HOSTNAMES[@]})
  SCHEMA_REGISTRY_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.enabled")
  SCHEMA_REGISTRY_SSL_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.port")
  SCHEMA_REGISTRY_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "port")
  if [[ "$SCHEMA_REGISTRY_SSL_ENABLED" == "true" ]]; then
    export SCHEMAREGISTRY_URL="https://$HOSTNAME:$SCHEMA_REGISTRY_SSL_PORT"
  else
    export SCHEMAREGISTRY_URL="http://$HOSTNAME:$SCHEMA_REGISTRY_PORT"
  fi
fi

if [[ "$SSL_ENABLED" == "true" ]]; then
  perl -pi -e "s#\{{TLS_ONOFF}}#on#" $CONF_DIR/$2-conf/Caddyfile
  perl -pi -e "s#\#https#https#" $CONF_DIR/$2-conf/Caddyfile
  perl -pi -e "s#\#tls self_signed#tls self_signed#" $CONF_DIR/$2-conf/Caddyfile

else
  perl -pi -e "s#\{{TLS_ONOFF}}#off#" $CONF_DIR/$2-conf/Caddyfile
  perl -pi -e "s#\#http#http#" $CONF_DIR/$2-conf/Caddyfile
fi

cp -r $PARROT_MANAGER_HOME/$2 $CONF_DIR

chmod +x $HOME_UI/start

exec $CONF_DIR/$2/start
