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

KAFKA_REST_CONF_FILE="$CONF_DIR/kafka-rest-conf/kafka-rest.properties"

# Example first line of version file: version=0.1.0-3.2.2
KAFKA_REST_VERSION=$(grep "^version=" $KAFKA_REST_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Confluent Kafka Rest version found: ${KAFKA_REST_VERSION}"

# Generating Zookeeper quorum
QUORUM=$ZK_QUORUM
if [[ -n $CHROOT ]]; then
  QUORUM="${QUORUM}${CHROOT}"
fi

# Add Listener
if [[ ${SSL_ENABLED} == "true" ]]; then
    LISTENERS="https://0.0.0.0:${SSL_PORT}"
else
    LISTENERS="http://0.0.0.0:${PORT}"
fi

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

# Define log4j.properties
LOG_DIR=/var/log/kafka-rest
export KAFKAREST_LOG4J_OPTS="-Dlog4j.configuration=file:$CONF_DIR/log4j.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - KAFKA REST PROXY"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                     `date`"
echo -e "# PORT:                     $PORT"
echo -e "# HOST:                     $HOST"
echo -e "# PWD:                      `pwd`"
echo -e "# CONF_DIR:                 $CONF_DIR"
echo -e "# CONF_FILE:                $KAFKA_REST_CONF_FILE"
echo -e "# KAFKA_REST_HOME:          $KAFKA_REST_HOME"
echo -e "# KAFKA_REST_VERSION:       $KAFKA_REST_VERSION"
echo -e "# KAFKAREST_LOG4J_OPTS:     $KAFKAREST_LOG4J_OPTS"
echo -e "# ZK_QUORUM:                $QUORUM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:              $SSL_ENABLED"
echo -e "# SSL_PORT:                 $SSL_PORT"
echo -e "# SSL_KEYSTORE_LOCATION:    $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:    $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION:  $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD:  $SSL_TRUSTSTORE_PASSWORD"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# CLIENT_SECURITY_MODE:     $CLIENT_SECURITY_MODE"
echo -e "# CLIENT_SECURITY_PROTOCOL: $CLIENT_SECURITY_PROTOCOL"
echo -e "# KERBEROS_AUTH_ENABLED:    $KERBEROS_AUTH_ENABLED"
echo -e "# KAFKA_PRINCIPAL:          $KAFKA_PRINCIPAL"
echo -e "######################################################################################"

perl -pi -e "s#\#zookeeper.connect={{QUORUM}}#zookeeper.connect=${QUORUM}#" $KAFKA_REST_CONF_FILE
perl -pi -e "s#\#listeners={{LISTENERS}}#listeners=${LISTENERS}#" $KAFKA_REST_CONF_FILE
perl -pi -e "s#\{{SCHEMA_REGISTRY_URL}}#${SCHEMA_REGISTRY_URL}#" $KAFKA_REST_CONF_FILE
perl -pi -e "s#^client.#$CLIENT_SECURITY_MODE.#" $KAFKA_REST_CONF_FILE

if [[ (${CLIENT_SECURITY_PROTOCOL} == "SASL_PLAINTEXT") || (${CLIENT_SECURITY_PROTOCOL} == "SASL_SSL") ]]; then
  # If user has not provided safety valve, replace JAAS_CONFIGS's placeholder
  if [ -z "$JAAS_CONFIGS" ]; then
    KEYTAB_FILE="${CONF_DIR}/kafka_rest.keytab"
    JAAS_CONFIGS="
KafkaClient {
   com.sun.security.auth.module.Krb5LoginModule required
   doNotPrompt=true
   useKeyTab=true
   storeKey=true
   keyTab=\"$KEYTAB_FILE\"
   principal=\"$KAFKA_PRINCIPAL\";
};
Client {
   com.sun.security.auth.module.Krb5LoginModule required
   doNotPrompt=true
   useKeyTab=true
   storeKey=true
   keyTab=\"$KEYTAB_FILE\"
   principal=\"$KAFKA_PRINCIPAL\";
};
"
  fi
  echo "${JAAS_CONFIGS}" > $CONF_DIR/jaas.conf
  export KAFKAREST_OPTS="-Djava.security.auth.login.config=${CONF_DIR}/jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf"
fi

# Run Confluent Kafka REST Proxy
exec $KAFKA_REST_HOME/bin/kafka-rest-start $KAFKA_REST_CONF_FILE
