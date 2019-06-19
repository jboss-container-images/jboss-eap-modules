#!/bin/sh

# Centralised configuration file to set variables that affect the launch scripts in wildfly-cekit-modules.

# Scripts that modify the configuration. Either via xml marker replacement or via CLI commands.
# wildfly-cekit-modules will look for each of the listed files and run them if they exist.
CONFIG_SCRIPT_CANDIDATES=(
  $JBOSS_HOME/bin/launch/backward-compatibility.sh
  $JBOSS_HOME/bin/launch/configure_extensions.sh
  $JBOSS_HOME/bin/launch/passwd.sh
  $JBOSS_HOME/bin/launch/messaging.sh
  $JBOSS_HOME/bin/launch/datasource.sh
  $JBOSS_HOME/bin/launch/resource-adapter.sh
  $JBOSS_HOME/bin/launch/admin.sh
  $JBOSS_HOME/bin/launch/ha.sh
  $JBOSS_HOME/bin/launch/jgroups.sh
  $JBOSS_HOME/bin/launch/https.sh
  $JBOSS_HOME/bin/launch/elytron.sh
  $JBOSS_HOME/bin/launch/json_logging.sh
  $JBOSS_HOME/bin/launch/configure_logger_category.sh
  $JBOSS_HOME/bin/launch/security-domains.sh
  $JBOSS_HOME/bin/launch/keycloak.sh
  $JBOSS_HOME/bin/launch/deploymentScanner.sh
  $JBOSS_HOME/bin/launch/ports.sh
  $JBOSS_HOME/bin/launch/access_log_valve.sh
  $JBOSS_HOME/bin/launch/filters.sh
  /opt/run-java/proxy-options
  $JBOSS_HOME/bin/launch/jboss_modules_system_pkgs.sh
)
# The server configuration file to use. If not set, wildfly-cekit-modules defaults to standalone.xml.
# For EAP we want standalone-openshift.xml
WILDFLY_SERVER_CONFIGURATION=standalone-openshift.xml
# The configuration adjustment mode. For EAP we want both xml marker replacement and CLI commands.
# Notice that the value of this variable must be aligned with the value configured in s2i-core-hooks
CONFIG_ADJUSTMENT_MODE="xml_cli"