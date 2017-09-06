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

CADDYFILE="$CONF_DIR/$2-conf/Caddyfile"

# Example first line of version file: version=0.1.0
PARROT_MANAGER_VERSION=$(grep "^version=" $PARROT_MANAGER_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Parrot Manager version found: ${PARROT_MANAGER_VERSION}"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT MANAGER"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# COMMAND:                         $1"
echo -e "# SERVICE:                         $2"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                            `date`"
echo -e "# PORT:                            $PORT"
echo -e "# HOST:                            $HOST"
echo -e "# CONF_DIR:                        $CONF_DIR"
echo -e "# PARROT_MANAGER_HOME:             $PARROT_MANAGER_HOME"
echo -e "# PARROT_MANAGER_VERSION:          $PARROT_MANAGER_VERSION"
echo -e "# CSD_JAVA_OPTS:                   $CSD_JAVA_OPTS"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                     $SSL_ENABLED"
echo -e "# SSL_PORT:                        $SSL_PORT"
echo -e "# SSL_GENERATE_SELF_SIGNED:        $SSL_GENERATE_SELF_SIGNED"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# PROXY_SKIP_VERIFY:               $PROXY_SKIP_VERIFY"

export LOG_FILE_NAME=$2
export HOME_UI=$CONF_DIR/$2

if [[ "$2" == "kafka-topics-ui" ]]; then
  HOSTNAMES=$(extract_peer_hosts "kafka-rest")
  HOSTNAME=(${HOSTNAMES[@]})
  KAFKA_REST_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "kafka-rest" "ssl.enabled")
  KAFKA_REST_SSL_PORT=$(extract_peer_config_value $HOSTNAME "kafka-rest" "ssl.port")
  KAFKA_REST_PORT=$(extract_peer_config_value $HOSTNAME "kafka-rest" "port")
  if [[ ${KAFKA_REST_SSL_ENABLED} == "true" ]]; then
    export KAFKA_REST_PROXY_URL="https://$HOSTNAME:$KAFKA_REST_SSL_PORT"
  else
    export KAFKA_REST_PROXY_URL="http://$HOSTNAME:$KAFKA_REST_PORT"
  fi
  echo -e "# PROXY:                           $PROXY"
  echo -e "# KAFKA_REST_PROXY_URL:            $KAFKA_REST_PROXY_URL"
  echo -e "# KAFKA_REST_SSL_ENABLED:          $KAFKA_REST_SSL_ENABLED"
  echo -e "# KAFKA_REST_PORT:                 $KAFKA_REST_PORT"
  echo -e "# KAFKA_REST_SSL_PORT:             $KAFKA_REST_SSL_PORT"
elif [[ "$2" == "kafka-connect-ui" ]]; then
  # Get the list where the Parrot Stream Role is distributed
  HOSTNAMES=$(extract_peer_hosts "parrot-stream")
  CONNECT_URL=""
  while read -r host; do
    PARROT_STREAM_REST_PORT=$(extract_peer_config_value $host "parrot-stream" "rest.port")
    CONNECT_URL="$CONNECT_URL,http://$host:$PARROT_STREAM_REST_PORT"
  done <<< "$HOSTNAMES"
  export CONNECT_URL=${CONNECT_URL#","}
  echo -e "# PARROT_STREAM_CONNECT_URL:       $CONNECT_URL"

  # Get the hostname where the Kafka Topics UI is distributed
  HOSTNAMES=$(extract_peer_hosts "kafka-topics-ui")
  HOSTNAME=(${HOSTNAMES[@]})
  KAFKA_TOPICS_UI_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "kafka-topics-ui" "ssl.enabled")
  KAFKA_TOPICS_UI_REST_PORT=$(extract_peer_config_value $HOSTNAME "kafka-topics-ui" "port")
  KAFKA_TOPICS_UI_SSL_REST_PORT=$(extract_peer_config_value $HOSTNAME "kafka-topics-ui" "ssl.port")
  echo -e "#-------------------------------------------------------------------------------------"
  echo -e "# KAFKA_TOPICS_UI_SSL_ENABLED:     $KAFKA_TOPICS_UI_SSL_ENABLED"
  echo -e "# KAFKA_TOPICS_UI_REST_PORT:       $KAFKA_TOPICS_UI_REST_PORT"
  echo -e "# KAFKA_TOPICS_UI_SSL_REST_PORT:   $KAFKA_TOPICS_UI_SSL_REST_PORT"
  if [[ "$KAFKA_TOPICS_UI_SSL_ENABLED" == "true" ]]; then
    export KAFKA_TOPICS_UI="https://$HOSTNAME:$KAFKA_TOPICS_UI_SSL_REST_PORT"
  else
    export KAFKA_TOPICS_UI="http://$HOSTNAME:$KAFKA_TOPICS_UI_REST_PORT"
  fi
elif [[ "$2" == "schema-registry-ui" ]]; then
  HOSTNAMES=$(extract_peer_hosts "schema-registry")
  HOSTNAME=(${HOSTNAMES[@]})
  SCHEMA_REGISTRY_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.enabled")
  SCHEMA_REGISTRY_SSL_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.port")
  SCHEMA_REGISTRY_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "port")
  if [[ ${SCHEMA_REGISTRY_SSL_ENABLED} == "true" ]]; then
    export SCHEMAREGISTRY_URL="https://$HOSTNAME:$SCHEMA_REGISTRY_SSL_PORT"
  else
    export SCHEMAREGISTRY_URL="http://$HOSTNAME:$SCHEMA_REGISTRY_PORT"
  fi
  echo -e "# PROXY:                           $PROXY"
  echo -e "# SCHEMAREGISTRY_URL:              $SCHEMAREGISTRY_URL"
  echo -e "# SCHEMA_REGISTRY_SSL_ENABLED:     $SCHEMA_REGISTRY_SSL_ENABLED"
  echo -e "# SCHEMA_REGISTRY_PORT:            $SCHEMA_REGISTRY_PORT"
  echo -e "# ALLOW_GLOBAL:                    $ALLOW_GLOBAL"
  echo -e "# ALLOW_TRANSITIVE:                $ALLOW_TRANSITIVE"
fi

echo -e "######################################################################################"

if [[ ${SSL_ENABLED} == "true" ]]; then
  perl -pi -e "s#\{{TLS_ONOFF}}#on#" $CADDYFILE
  perl -pi -e "s#\#{{HTTPS}}#https#" $CADDYFILE
  if [[ ${SSL_GENERATE_SELF_SIGNED} == "true" ]]; then
    perl -pi -e "s#\#tls {{CERT}}#tls self_signed#" $CADDYFILE
  else
    perl -pi -e "s#\#tls {{CERT}}#tls ${SSL_CERTIFICATE_LOCATION} ${SSL_PRIVATEKEY_LOCATION}#" $CADDYFILE
  fi
else
  perl -pi -e "s#\{{TLS_ONOFF}}#off#" $CADDYFILE
  perl -pi -e "s#\#{{HTTP}}#http#" $CADDYFILE
fi

cp -r $PARROT_MANAGER_HOME/$2 $CONF_DIR

chmod +x $HOME_UI/start

exec $CONF_DIR/$2/start
