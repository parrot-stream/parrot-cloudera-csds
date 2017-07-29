#!/bin/bash

set -x

DEFAULT_SCHEMA_REGISTRY_HOME=/usr/share/java/schema-registry
SCHEMA_REGISTRY_HOME=${SCHEMA_REGISTRY_HOME:-$DEFAULT_SCHEMA_REGISTRY_HOME}

# example first line of version file: version=0.1.0-3.2.2
SCHEMA_REGISTRY_VERSION=$(grep "^version=" $SCHEMA_REGISTRY_HOME/../../cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Confluent Schema Registry version found: ${SCHEMA_REGISTRY_VERSION}"

# For better debugging
echo -e "Date: `date`"
echo -e "Host: $HOST"
echo -e "Pwd: `pwd`"
echo -e "CONF_DIR: $CONF_DIR"
echo -e "SCHEMA_REGISTRY_HOME: $KAFKA_HOME"
echo -e "SCHEMA_REGISTRY_VERSION: $SCHEMA_REGISTRY_VERSION"
echo -e "Zookeeper Quorum: $ZK_QUORUM"
echo -e "Zookeeper Chroot: $CHROOT"
echo -e "PORT: $PORT"

# Generating Zookeeper quorum
QUORUM=$ZK_QUORUM
if [[ -n $CHROOT ]]; then
	QUORUM="${QUORUM}${CHROOT}"
fi
echo "Final Zookeeper Quorum is $QUORUM"

# Replace kafkastore.connection.urlplaceholder
perl -pi -e "s#\#kafkastore.connection.url={{QUORUM}}#kafkastore.connection.url=${QUORUM}#" $CONF_DIR/schema-registry.properties

# And finally run Kafka itself
exec $SCHEMA_REGISTRY_HOME/bin/schema-registry-start.sh $CONF_DIR/schema-registry.properties
