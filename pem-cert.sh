#!/bin/bash

function usage {
  echo -e "#################################################################################################################################################"
  echo -e "  Usage:"
  echo -e "             ./pem-cert.sh COMMAND [OPTIONS]"
  echo -e ""
  echo -e "  Example:"
  echo -e ""
  echo -e "    ./pem-cert.sh create -a=schema-registry -h=quickstart.cloudera -sd=/opt/cloudera/security"
  echo -e ""
  echo -e "  Commands:"
  echo -e ""
  echo -e "     create          		Creates a new Self Signed Certificate"
  echo -e ""
  echo -e "  Options:"
  echo -e ""
  echo -e "     -a, --alias     	        Certificate alias name"
  echo -e "     -h, --hostname			FQDN of the hostname of the Certificate"
  echo -e "     -sd, --security-dir             Base dir where pem keystore file is created (es. /opt/cloudera/security)"
  echo -e ""
  echo -e "----------------------------------------------------------------------------------------------------------------------------------------------"
  echo -e "  COMMAND:  $COMMAND"
  echo -e "  -a        $ALIAS"
  echo -e "  -h        $HOSTNAME"
  echo -e "  -sd       $SECURITY_BASE_DIR"
echo -e "#################################################################################################################################################"
}

function check_command {
  for i in "$@"
  do
  case $i in
    create)
    COMMAND=$i
    shift
    ;;
    -a*|--alias*)
    set -- "$i"
    IFS="="; declare -a Array=($*)
    ALIAS=${Array[1]}
    shift
    ;;
    -h*|--hostname*)
    set -- "$i"
    IFS="="; declare -a Array=($*)
    HOSTNAME=${Array[1]}
    shift
    ;;
    -sd*|--security-dir*)
    set -- "$i"
    IFS="="; declare -a Array=($*)
    SECURITY_BASE_DIR=${Array[1]}
    shift
    ;;
  esac
  done

  echo -e "#################################################################################################################################################"
  echo -e "  COMMAND:  $COMMAND"
  echo -e "  -a        $ALIAS"
  echo -e "  -h        $HOSTNAME"
  echo -e "  -sd       $SECURITY_BASE_DIR"
  echo -e "#################################################################################################################################################"

  if [[ (-z "$COMMAND") ]]; then
    usage
    exit 0
  fi

}

check_command "$@"

if [[ "$COMMAND" == "create" ]]; then
  mkdir -p $SECURITY_BASE_DIR
  openssl req \
    -new \
    -newkey rsa:4096 \
    -days 3650 \
    -x509 \
    -nodes \
    -subj "/C=IT/ST=Italy/L=Rome/O=Parrot/CN=$HOSTNAME" \
    -keyout $SECURITY_BASE_DIR/$ALIAS-key.pem \
    -out $SECURITY_BASE_DIR/$ALIAS-cert.pem
fi
