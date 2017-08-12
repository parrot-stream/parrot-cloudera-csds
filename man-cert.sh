#!/bin/bash

function usage {
  echo -e "#################################################################################################################################################"
  echo -e "  Usage:"
  echo -e "             ./man-cert.sh COMMAND [OPTIONS]"
  echo -e ""
  echo -e "  Example:"
  echo -e ""
  echo -e "    ./man-cert.sh create -a=schema-registry -h=quickstart.cloudera -sd=/opt/cloudera/security"
  echo -e "    ./man-cert.sh delete -a=schema-registry -sd=/opt/cloudera/security"
  echo -e "    ./man-cert.sh list   -sd=/opt/cloudera/security"
  echo -e ""
  echo -e "  Commands:"
  echo -e ""
  echo -e "     create          		Creates a new Self Signed Certificate"
  echo -e "     delete          		Deletes an existing Self Signed Certificate"
  echo -e "     list          		        List Certificates in the Keystore"
  echo -e ""
  echo -e "  Options:"
  echo -e ""
  echo -e "     -a, --alias     		Certificate alias name"
  echo -e "     -h, --hostname			FWDN of the hostname of the Certificate"
  echo -e "     -sd, --security-dir		Base dir where jks (keystore) and x509 (certificates) dir are created (es. /opt/cloudera/security)"
  echo -e ""
  echo -e "----------------------------------------------------------------------------------------------------------------------------------------------"
  echo -e "  COMMAND:  $COMMAND"
  echo -e "  -a:       $ALIAS"
  echo -e "  -h:       $HOSTNAME"
  echo -e "  -sd       $SECURITY_BASE_DIR"
echo -e "#################################################################################################################################################"
}

function check_command {
  for i in "$@"
  do
  case $i in
    create|delete|list)
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
  echo -e "       -a:  $ALIAS"
  echo -e "       -h:  $HOSTNAME"
  echo -e "       -sd  $SECURITY_BASE_DIR"
  echo -e "#################################################################################################################################################"

  if [[ (-z "$COMMAND") ]]; then
    usage
    exit 0
  fi

}

check_command "$@"

if [[ "$COMMAND" == "create" ]]; then
  mkdir -p $SECURITY_BASE_DIR/jks
  mkdir -p $SECURITY_BASE_DIR/x509
  keytool -genkeypair -keystore $SECURITY_BASE_DIR/jks/$ALIAS-keystore.jks -keyalg RSA -keysize 2048 -alias $ALIAS -dname \
"CN=$HOSTNAME,OU=Security,O=Parrot,L=Rome,ST=Italy,C=IT" -storepass password -keypass password -validity 3650

  if [ ! -f "$JAVA_HOME/jre/lib/security/jssecacerts" ]; then
    cp -f $JAVA_HOME/jre/lib/security/cacerts $JAVA_HOME/jre/lib/security/jssecacerts
  fi

  keytool -export -alias $ALIAS -keystore $SECURITY_BASE_DIR/jks/$ALIAS-keystore.jks -rfc -file $SECURITY_BASE_DIR/x509/$HOSTNAME.pem
  keytool -import -alias $ALIAS -file $SECURITY_BASE_DIR/x509/$HOSTNAME.pem -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass changeit -noprompt
  keytool -importkeystore -srckeystore $SECURITY_BASE_DIR/jks/$ALIAS-keystore.jks -srcstorepass password -srckeypass password -destkeystore /tmp/$ALIAS-keystore.p12 -deststoretype PKCS12 -srcalias $ALIAS -deststorepass password -destkeypass password
  openssl pkcs12 -in /tmp/$ALIAS-keystore.p12 -passin pass:password -nocerts -out $SECURITY_BASE_DIR/x509/$HOSTNAME.key -passout pass:password
   
  chown -R cloudera-scm:cloudera-scm $SECURITY_BASE_DIR
  chmod -R 755 $SECURITY_BASE_DIR

  rm -rf /tmp/$ALIAS-keystore.p12

  cd $SECURITY_BASE_DIR/x509 && c_rehash

fi

if [[ "$COMMAND" == "delete" ]]; then
  rm -rf $SECURITY_BASE_DIR
  rm -f $SECURITY_BASE_DIR/x509/$HOSTNAME.key $SECURITY_BASE_DIR/x509/$HOSTNAME.pem
  keytool -delete -alias $ALIAS -keystore $SECURITY_BASE_DIR/jks/$ALIAS-keystore.jks
  keytool -delete -alias $ALIAS -keystore $JAVA_HOME/jre/lib/security/jssecacerts
fi

if [[ "$COMMAND" == "list" ]]; then
  sudo keytool -list -keystore $SECURITY_BASE_DIR/jks/$ALIAS-keystore.jks
  sudo keytool -list -keystore $JAVA_HOME/jre/lib/security/jssecacerts
fi
