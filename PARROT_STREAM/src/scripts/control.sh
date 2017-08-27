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
PARROT_STREAM_LOG4J_CONF_FILE="$CONF_DIR/parrot-stream-conf/log4j.properties"
KAFKA_OPTS=""

# Example first line of version file: version=0.1.0-3.2.2
PARROT_STREAM_VERSION=$(grep "^version=" $PARROT_STREAM_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Parrot Stream version found: ${PARROT_STREAM_VERSION}"

# Define log4j.properties
export LOG_DIR=/var/log/parrot-stream
KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$PARROT_STREAM_LOG4J_CONF_FILE"
export KAFKA_LOG4J_OPTS="-Dparrot-stream.log.dir=$LOG_DIR $KAFKA_LOG4J_OPTS"

# SSL Configs
if [[ ${SSL_ENABLED} == "true" ]]; then
  SSL_CONFIGS=$(cat parrot-stream-conf/ssl.properties)
  perl -pi -e "s#\#ssl.configs={{SSL_CONFIGS}}#${SSL_CONFIGS}#" $PARROT_STREAM_CONF_FILE
else
  perl -pi -e "s#\#ssl.configs={{SSL_CONFIGS}}##" $PARROT_STREAM_CONF_FILE
fi

perl -pi -e "s#{{REST_PORT}}#${PORT}#" $PARROT_STREAM_CONF_FILE

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT STREAM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                      `date`"
echo -e "# PORT:                      $PORT"
echo -e "# HOST:                      $HOST"
echo -e "# PWD:                       `pwd`"
echo -e "# CONF_DIR:                  $CONF_DIR"
echo -e "# PARROT_STREAM_HOME:        $PARROT_STREAM_HOME"
echo -e "# PARROT_STREAM_VERSION:     $PARROT_STREAM_VERSION"
echo -e "# KAFKA_LOG4J_OPTS:          $KAFKA_LOG4J_OPTS"
echo -e "# CSD_JAVA_OPTS:             $CSD_JAVA_OPTS"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:               $SSL_ENABLED"
echo -e "# SSL_KEYSTORE_LOCATION:     $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:     $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION:   $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD:   $SSL_TRUSTSTORE_PASSWORD"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# KERBEROS_AUTH_ENABLED:     $KERBEROS_AUTH_ENABLED"
echo -e "# KAFKA_PRINCIPAL:           $KAFKA_PRINCIPAL"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# JAVA_HEAP_SIZE_MB:         $JAVA_HEAP_SIZE_MB"
echo -e "######################################################################################"

if [[ ${KERBEROS_AUTH_ENABLED} == "true" ]]; then
  # If user has not provided safety valve, replace JAAS_CONFIGS's placeholder
  if [ -z "$JAAS_CONFIGS" ]; then
    KEYTAB_FILE="${CONF_DIR}/parrot_stream.keytab"
 #   SASL_JAAS_CONFIGS="com.sun.security.auth.module.Krb5LoginModule required doNotPrompt=true useKeyTab=true storeKey=true keyTab=\"$KEYTAB_FILE\" principal=\"$KAFKA_PRINCIPAL\";"
    JAAS_CONFIGS="
KafkaClient {
   com.sun.security.auth.module.Krb5LoginModule required
   doNotPrompt=true
   useKeyTab=true
   storeKey=true
   keyTab=\"$KEYTAB_FILE\"
   principal=\"$KAFKA_PRINCIPAL\";
};"
  fi
  echo "${JAAS_CONFIGS}" > $CONF_DIR/jaas.conf
  KAFKA_OPTS="${KAFKA_OPTS} -Djava.security.auth.login.config=${CONF_DIR}/jaas.conf"
  if [[ ${SSL_ENABLED} == "true" ]]; then
    perl -pi -e "s#{{SECURITY_PROTOCOL}}#SASL_SSL#" $PARROT_STREAM_CONF_FILE
  else
    perl -pi -e "s#{{SECURITY_PROTOCOL}}#SASL_PLAINTEXT#" $PARROT_STREAM_CONF_FILE
  fi

  if [[ ${DEBUG} == "true" ]]; then
    KAFKA_OPTS="${KAFKA_OPTS} -Dsun.security.krb5.debug=true"
  fi
else
  perl -pi -e "s#\#sasl.jaas.config={{SASL_JAAS_CONFIG}}##" $PARROT_STREAM_CONF_FILE
  if [[ ${SSL_ENABLED} == "true" ]]; then
    perl -pi -e "s#{{SECURITY_PROTOCOL}}#SSL#" $PARROT_STREAM_CONF_FILE
  else
    perl -pi -e "s#{{SECURITY_PROTOCOL}}#PLAINTEXT#" $PARROT_STREAM_CONF_FILE
  fi
fi

# Add Schema Registry URL
HOSTNAMES=$(extract_peer_hosts "schema-registry")
SCHEMA_REGISTRY_URL=""
while read -r host; do
  SCHEMA_REGISTRY_SSL_ENABLED=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.enabled")
  SCHEMA_REGISTRY_SSL_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "ssl.port")
  SCHEMA_REGISTRY_PORT=$(extract_peer_config_value $HOSTNAME "schema-registry" "port")
  if [[ ${SCHEMA_REGISTRY_SSL_ENABLED} == "true" ]]; then
    SCHEMA_REGISTRY_URL="$SCHEMA_REGISTRY_URL,https://$host:$SCHEMA_REGISTRY_SSL_PORT"
  else
    SCHEMA_REGISTRY_URL="$SCHEMA_REGISTRY_URL,http://$host:$SCHEMA_REGISTRY_PORT"
  fi
done <<< "$HOSTNAMES"
export SCHEMA_REGISTRY_URL=${SCHEMA_REGISTRY_URL#","}

# Replace listeners placeholder with SCHEMA_REGISTRY_URL
perl -pi -e "s#\{{SCHEMA_REGISTRY_URL}}#${SCHEMA_REGISTRY_URL}#" $PARROT_STREAM_CONF_FILE

# Java Opts
export KAFKA_HEAP_OPTS="-Xmx${JAVA_HEAP_SIZE_MB}M"
export KAFKA_OPTS

# Run Parrot Stream
exec $PARROT_STREAM_HOME/kafka/bin/connect-distributed.sh $PARROT_STREAM_CONF_FILE
