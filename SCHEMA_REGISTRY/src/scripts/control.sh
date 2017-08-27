#!/bin/bash

set -x

SCHEMA_REGISTRY_CONF_FILE=$CONF_DIR/schema-registry-conf/schema-registry.properties
SCHEMA_REGISTRY_LOG4J_CONF_FILE=$CONF_DIR/schema-registry-conf/log4j.properties
SCHEMA_REGISTRY_OPTS=""

# Example first line of version file: version=0.1.0-3.2.2
SCHEMA_REGISTRY_VERSION=$(grep "^version=" $SCHEMA_REGISTRY_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Confluent Schema Registry version found: ${SCHEMA_REGISTRY_VERSION}"

# Generating Zookeeper quorum
QUORUM=$ZK_QUORUM
if [[ -n $CHROOT ]]; then
  QUORUM="${QUORUM}${CHROOT}"
fi

# Define log4j.properties
export LOG_DIR=/var/log/schema-registry
SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j.configuration=file:$SCHEMA_REGISTRY_LOG4J_CONF_FILE"
export SCHEMA_REGISTRY_LOG4J_OPTS="-Dschema-registry.log.dir=$LOG_DIR $SCHEMA_REGISTRY_LOG4J_OPTS"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - SCHEMA REGISTRY"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                         `date`"
echo -e "# PORT:                         $PORT"
echo -e "# HOST:                         $HOST"
echo -e "# PWD:                          `pwd`"
echo -e "# CONF_DIR:                     $CONF_DIR"
echo -e "# CONF_FILE:                    $CONF_FILE"
echo -e "# SCHEMA_REGISTRY_HOME:         $SCHEMA_REGISTRY_HOME"
echo -e "# SCHEMA_REGISTRY_VERSION:      $SCHEMA_REGISTRY_VERSION"
echo -e "# SCHEMA_REGISTRY_LOG4J_OPTS:   $SCHEMA_REGISTRY_LOG4J_OPTS"
echo -e "# ZK_QUORUM:                    $QUORUM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                  $SSL_ENABLED"
echo -e "# SSL_PORT:                     $SSL_PORT"
echo -e "# SSL_KEYSTORE_LOCATION:        $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_LOCATION:      $SSL_TRUSTSTORE_LOCATION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# KERBEROS_AUTH_ENABLED:        $KERBEROS_AUTH_ENABLED"
echo -e "# KAFKASTORE_SECURITY_PROTOCOL: $KAFKASTORE_SECURITY_PROTOCOL"
echo -e "# KAFKA_PRINCIPAL:              $KAFKA_PRINCIPAL"
echo -e "######################################################################################"

if [[ -z ${ZK_PRINCIPAL_NAME} ]]; then
    ZK_PRINCIPAL_NAME="zookeeper"
fi

# Generate JAAS config file
if [[ (${KAFKASTORE_SECURITY_PROTOCOL} == "SASL_PLAINTEXT") || (${KAFKASTORE_SECURITY_PROTOCOL} == "SASL_SSL") ]]; then

  REALM="${KAFKA_PRINCIPAL#k*@}"
  perl -pi -e "s#\#authentication.realm={{REALM}}#authentication.realm=${REALM}#" $SCHEMA_REGISTRY_CONF_FILE

  # If user has not provided safety valve, replace JAAS_CONFIGS's placeholder
  if [ -z "$JAAS_CONFIGS" ]; then
    KEYTAB_FILE="${CONF_DIR}/schema_registry.keytab"
    JAAS_CONFIGS="
KafkaClient {
   com.sun.security.auth.module.Krb5LoginModule required
   doNotPrompt=true
   useKeyTab=true
   storeKey=true
   useTicketCache=true
   keyTab=\"$KEYTAB_FILE\"
   principal=\"$KAFKA_PRINCIPAL\";
};

Client {
   com.sun.security.auth.module.Krb5LoginModule required
   doNotPrompt=true
   useKeyTab=true
   storeKey=true
   useTicketCache=true
   keyTab=\"$KEYTAB_FILE\"
   principal=\"$KAFKA_PRINCIPAL\";
};"
  fi
  echo "${JAAS_CONFIGS}" > $CONF_DIR/jaas.conf
  SCHEMA_REGISTRY_OPTS="${SCHEMA_REGISTRY_OPTS} -Djava.security.auth.login.config=${CONF_DIR}/jaas.conf"
  perl -pi -e "s#zookeeper.set.acl=false#zookeeper.set.acl=true#" $SCHEMA_REGISTRY_CONF_FILE
  SCHEMA_REGISTRY_OPTS="${SCHEMA_REGISTRY_OPTS} -Dzookeeper.sasl.client.username=${ZK_PRINCIPAL_NAME}"
fi

if [[ ${DEBUG} == "true" ]]; then
  SCHEMA_REGISTRY_OPTS="${SCHEMA_REGISTRY_OPTS} -Dsun.security.krb5.debug=${DEBUG} -Djavax.net.debug=all"
fi

# Add Listener
if [[ ${SSL_ENABLED} == "true" ]]; then
  SSL_CONFIGS=$(cat schema-registry-conf/ssl.properties)
  LISTENERS="https://0.0.0.0:${SSL_PORT}"
  perl -pi -e "s#\#ssl.configs={{SSL_CONFIGS}}#${SSL_CONFIGS}#" $SCHEMA_REGISTRY_CONF_FILE
else
  LISTENERS="http://0.0.0.0:${PORT}"
  perl -pi -e "s#\#ssl.configs={{SSL_CONFIGS}}##" $SCHEMA_REGISTRY_CONF_FILE
fi

perl -pi -e "s#\#kafkastore.connection.url={{QUORUM}}#kafkastore.connection.url=${QUORUM}#" $SCHEMA_REGISTRY_CONF_FILE
perl -pi -e "s#\#listeners={{LISTENERS}}#listeners=${LISTENERS}#" $SCHEMA_REGISTRY_CONF_FILE

export SCHEMA_REGISTRY_OPTS

# Run Confluent Schema Registry
exec $SCHEMA_REGISTRY_HOME/bin/schema-registry-start $SCHEMA_REGISTRY_CONF_FILE
