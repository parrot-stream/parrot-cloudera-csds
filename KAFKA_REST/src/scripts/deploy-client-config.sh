#!/bin/bash

set -x

KAFKA_REST_CLIENT_CONF_DIR="$CONF_DIR/kafka-rest-conf"
KAFKA_REST_CLIENT_CONF_FILE="$KAFKA_REST_CLIENT_CONF_DIR/kafka-rest-client.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - KAFKA REST: DEPLOY CLIENT CONFIGURATION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                       `date`"
echo -e "# PORT:                       $PORT"
echo -e "# HOST:                       $HOST"
echo -e "# PWD:                        `pwd`"
echo -e "# CONF_DIR:                   $KAFKA_REST_CLIENT_CONF_DIR"
echo -e "# CONF_FILE:                  $KAFKA_REST_CLIENT_CONF_FILE"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                $SSL_ENABLED"
echo -e "# SSL_PORT:                   $SSL_PORT"
echo -e "######################################################################################"
