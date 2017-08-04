#!/bin/bash

set -x

PARROT_STREAM_CLIENT_CONF_DIR="$CONF_DIR/parrot-stream-conf"
PARROT_STREAM_CLIENT_CONF_FILE="$PARROT_STREAM_CLIENT_CONF_DIR/parrot-stream-client.properties"

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - PARROT STREAM: DEPLOY CLIENT CONFIGURATION"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                       `date`"
echo -e "# PORT:                       $PORT"
echo -e "# HOST:                       $HOST"
echo -e "# PWD:                        `pwd`"
echo -e "# CONF_DIR:                   $PARROT_STREAM_CLIENT_CONF_DIR"
echo -e "# CONF_FILE:                  $PARROT_STREAM_CLIENT_CONF_FILE"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                $SSL_ENABLED"
echo -e "# SSL_PORT:                   $SSL_PORT"
echo -e "######################################################################################"
