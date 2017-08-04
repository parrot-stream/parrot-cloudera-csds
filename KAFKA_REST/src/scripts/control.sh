#!/bin/bash

set -x

DEFAULT_KAFKA_REST_HOME=/usr/share/java/kafka-rest
KAFKA_REST_HOME=${KAFKA_REST_HOME:-$DEFAULT_KAFKA_REST_HOME}
KAFKA_REST_CONF_FILE_NAME="kafka-rest.properties"

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

# Define log4j.properties
LOG_DIR=/var/log/kafka-rest
export KAFKAREST_LOG4J_OPTS="-Dlog4j.configuration=file:$CONF_DIR/log4j.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - KAFKA REST PROXY"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                    `date`"
echo -e "# PORT:                    $PORT"
echo -e "# HOST:                    $HOST"
echo -e "# PWD:                     `pwd`"
echo -e "# CONF_DIR:                $CONF_DIR"
echo -e "# KAFKA_REST_HOME:         $KAFKA_REST_HOME"
echo -e "# KAFKA_REST_VERSION:      $KAFKA_REST_VERSION"
echo -e "# KAFKAREST_LOG4J_OPTS:    $KAFKAREST_LOG4J_OPTS"
echo -e "# ZK_QUORUM:               $QUORUM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:             $SSL_ENABLED"
echo -e "# SSL_PORT:                $SSL_PORT"
echo -e "# SSL_KEYSTORE_LOCATION:   $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:   $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION: $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD: $SSL_TRUSTSTORE_PASSWORD"
echo -e "######################################################################################"

# Replace zookeeper.connect placeholder with ZooKeeper Quorum
perl -pi -e "s#\#zookeeper.connect={{QUORUM}}#zookeeper.connect=${QUORUM}#" $CONF_DIR/$KAFKA_REST_CONF_FILE_NAME

# Replace listeners placeholder with LISTENERS
perl -pi -e "s#\#listeners={{LISTENERS}}#listeners=${LISTENERS}#" $CONF_DIR/$KAFKA_REST_CONF_FILE_NAME

# Run Confluent Kafka REST Proxy
exec $KAFKA_REST_HOME/bin/kafka-rest-start $CONF_DIR/$KAFKA_REST_CONF_FILE_NAME
