#!/bin/sh
# Common Openshift EAP7 scripts
# The script takes into account the presence of the scripts that modify the
# standalone-opnshift.xml configuration file, assuming that if the
# script is in the file system, then the server was provisioned with the default
# configuration that the scripts modifies.

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi

CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml
LOGGING_FILE=$JBOSS_HOME/standalone/configuration/logging.properties

systime=$(date +%s)
#This is the cli file generated
CLI_SCRIPT_FILE=/tmp/cli-script-${systime}.cli
#This is the file used to log errors by the CLI execution
CLI_SCRIPT_ERROR_FILE=/tmp/cli-script-error-${systime}.cli
#The property file used to pass variables to jboss-cli.sh
CLI_SCRIPT_PROPERTY_FILE=/tmp/cli-script-property-${systime}.cli

echo "error_file=${CLI_SCRIPT_ERROR_FILE}" > ${CLI_SCRIPT_PROPERTY_FILE}

CONFIGURE_SCRIPTS=(
    $JBOSS_HOME/bin/launch/backward-compatibility.sh
    $JBOSS_HOME/bin/launch/configure_extensions.sh
    $JBOSS_HOME/bin/launch/passwd.sh
    );

if [ -f $JBOSS_HOME/bin/launch/messaging.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/messaging.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/datasource.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/datasource.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/resource-adapter.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/resource-adapter.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/admin.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/admin.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/ha.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/ha.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/jgroups.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/jgroups.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/https.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/https.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/elytron.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/elytron.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/json_logging.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/json_logging.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/configure_logger_category.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/configure_logger_category.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/security-domains.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/security-domains.sh)
fi

CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/jboss_modules_system_pkgs.sh)

if [ -f $JBOSS_HOME/bin/launch/keycloak.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/keycloak.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/deploymentScanner.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/deploymentScanner.sh)
fi

# This is an utility script
CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/ports.sh)

if [ -f $JBOSS_HOME/bin/launch/access_log_valve.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/access_log_valve.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/mp-config.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/mp-config.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/tracing.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/tracing.sh)
fi

if [ -f $JBOSS_HOME/bin/launch/filters.sh ]; then
    CONFIGURE_SCRIPTS+=($JBOSS_HOME/bin/launch/filters.sh)
fi

CONFIGURE_SCRIPTS+=(/opt/run-java/proxy-options)