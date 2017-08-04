#!/bin/bash

set -x

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
echo -e "# SSL_PORT:                $PORT"
echo -e "# SSL_KEYSTORE_LOCATION:   $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:   $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION: $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD: $SSL_TRUSTSTORE_PASSWORD"
echo -e "######################################################################################"


# Run Parrot Stream
exec $PARROT_STREAM_HOME/kafka/bin/connect-distributed.sh $CONF_DIR/connect-avro-distributed.properties
