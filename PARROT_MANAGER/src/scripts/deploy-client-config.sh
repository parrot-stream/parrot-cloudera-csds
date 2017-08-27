#!/bin/bash

set -x

PARROT_MANAGER_CLIENT_CONF_DIR="$CONF_DIR/parrot-manager-conf"
PARROT_MANAGER_CLIENT_CONF_FILE="$PARROT_MANAGER_CLIENT_CONF_DIR/parrot-manager-client.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT MANAGER: DEPLOY CLIENT CONFIGURATION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                       `date`"
echo -e "# PORT:                       $PORT"
echo -e "# HOST:                       $HOST"
echo -e "# PWD:                        `pwd`"
echo -e "# CONF_DIR:                   $PARROT_MANAGER_CLIENT_CONF_DIR"
echo -e "# CONF_FILE:                  $PARROT_MANAGER_CLIENT_CONF_FILE"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                $SSL_ENABLED"
echo -e "# SSL_PORT:                   $SSL_PORT"
echo -e "######################################################################################"
