#!/bin/bash

set -x

SCHEMA_REGISTRY_CLIENT_CONF_DIR="$CONF_DIR/schema-registry-conf"
SCHEMA_REGISTRY_CLIENT_CONF_FILE="$SCHEMA_REGISTRY_CLIENT_CONF_DIR/schema-registry-client.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - SCHEMA REGISTRY: DEPLOY CLIENT CONFIGURATION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                       `date`"
echo -e "# PORT:                       $PORT"
echo -e "# HOST:                       $HOST"
echo -e "# PWD:                        `pwd`"
echo -e "# CONF_DIR:                   $SCHEMA_REGISTRY_CLIENT_CONF_DIR"
echo -e "# CONF_FILE:                  $SCHEMA_REGISTRY_CLIENT_CONF_FILE"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                $SSL_ENABLED"
echo -e "# SSL_PORT:                   $SSL_PORT"
echo -e "######################################################################################"
