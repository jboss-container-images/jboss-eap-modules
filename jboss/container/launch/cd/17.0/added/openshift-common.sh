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

# The mode used to do the environment variable replacement. The values are:
# -none     - no adjustment should be done. This cam be forced if $CONFIG_IS_FINAL = true 
#               is passed in when starting the container
# -xml      - adjustment will happen via the legacy xml marker replacement
# -cli      - adjustment will happen via cli commands
# -xml_cli  - adjustment will happen via xml marker replacement if the marker is found. If not,
#               it will happen via cli commands
#
# Handling of the meanings of this are done by the
CONFIG_ADJUSTMENT_MODE="xml_cli"
if [ "${CONFIG_IS_FINAL^^}" = "TRUE" ]; then
    CONFIG_ADJUSTMENT_MODE="none"
fi

# Whether or not we should ignore xml markers
CLI_SCRIPT_ONLY_IGNORE_MARKERS=false

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

# Takes the following parameters:
# - $1      - the xml marker to test for
#
# Returns one of the following three values
# - ""      - no configuration should be done via the variables
# - "xml"   - configuration should happen via marker replacement
# - "cli"   - configuration should happen via cli commands
#
function getConfigurationMode() {
  local marker="${1}"
  local attemptXml="false"
  local viaCli="false"
  if [ "${CONFIG_ADJUSTMENT_MODE,,}" = "xml" ]; then
    attemptXml="true"
  elif  [ "${CONFIG_ADJUSTMENT_MODE,,}" = "cli" ]; then
    viaCli="true"
  elif  [ "${CONFIG_ADJUSTMENT_MODE,,}" = "xml_cli" ]; then
    attemptXml="true"
    viaCli="true"
  elif [ "${CONFIG_ADJUSTMENT_MODE,,}" != "none" ]; then
    echo "Bad CONFIG_ADJUSTMENT_MODE \'${CONFIG_ADJUSTMENT_MODE}\'"
    exit 1
  fi

  local configVia=""
  if [ "${attemptXml}" = "true" ]; then
    if grep -Fq "${marker}" $CONFIG_FILE; then
        configVia="xml"
    fi
  fi

  if [ -z "${configVia}" ]; then
    if [ "${viaCli}" = "true" ]; then
        configVia="cli"
    fi
  fi

  echo "${configVia}"
}