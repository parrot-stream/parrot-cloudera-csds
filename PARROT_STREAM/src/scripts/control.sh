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

PARROT_STREAM_CONF_FILE=$CONF_DIR/parrot-stream-conf/connect-avro-distributed.properties

function extract_peer_configs {
  while read row
  do
    echo "$row"
  done < /etc/$1/conf/$1-hostnames
}

function extract_peer_hosts {
  HOSTNAMES=`awk -F: '{print $1}' < kafka-rest-hostnames | sort | uniq`
}

# Example first line of version file: version=0.1.0-3.2.2
PARROT_STREAM_VERSION=$(grep "^version=" $PARROT_STREAM_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Parrot Stream version found: ${PARROT_STREAM_VERSION}"

# Define log4j.properties
export LOG_DIR=/var/log/parrot-stream
export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$CONF_DIR/log4j.properties"

# Add Listener
if [[ ${SSL_ENABLED} == "true" ]]; then
    ADVERTISED_PORT="${SSL_PORT}"
else
    ADVERTISED_PORT="${PORT}"
fi

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT STREAM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                    `date`"
echo -e "# PORT:                    $PORT"
echo -e "# HOST:                    $HOST"
echo -e "# PWD:                     `pwd`"
echo -e "# CONF_DIR:                $CONF_DIR"
echo -e "# PARROT_STREAM_HOME:      $PARROT_STREAM_HOME"
echo -e "# PARROT_STREAM_VERSION:   $PARROT_STREAM_VERSION"
echo -e "# KAFKA_LOG4J_OPTS:        $KAFKA_LOG4J_OPTS"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:             $SSL_ENABLED"
echo -e "# SSL_PORT:                $SSL_PORT"
echo -e "# SSL_KEYSTORE_LOCATION:   $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:   $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION: $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD: $SSL_TRUSTSTORE_PASSWORD"
echo -e "######################################################################################"

# Add Schema Registry URL
HOSTNAMES=$(extract_peer_hosts "schema-registry")
SCHEMA_REGISTRY_URL=""
while read -r host; do
  SCHEMA_REGISTRY_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl_enabled")
  SCHEMA_REGISTRY_SSL_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.port")
  SCHEMA_REGISTRY_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "port")
  if [[ "SCHEMA_REGISTRY_SSL_ENABLED" == "true" ]]; then
    SCHEMA_REGISTRY_URL="$SCHEMA_REGISTRY_URL,https://$host:$SCHEMA_REGISTRY_SSL_PORT"
  else
    SCHEMA_REGISTRY_URL="$SCHEMA_REGISTRY_URL,http://$host:$SCHEMA_REGISTRY_PORT"
  fi
done <<< "$HOSTNAMES"
export SCHEMA_REGISTRY_URL=${SCHEMA_REGISTRY_URL#","}

# Replace listeners placeholder with SCHEMA_REGISTRY_URL
perl -pi -e "s#\{{SCHEMA_REGISTRY_URL}}#${SCHEMA_REGISTRY_URL}#" $PARROT_STREAM_CONF_FILE

# Replace listeners placeholder with ADVERTISED_PORT
perl -pi -e "s#\{{ADVERTISED_PORT}}#${ADVERTISED_PORT}#" $PARROT_STREAM_CONF_FILE

# Run Parrot Stream
exec $PARROT_STREAM_HOME/kafka/bin/connect-distributed.sh $PARROT_STREAM_CONF_FILE
