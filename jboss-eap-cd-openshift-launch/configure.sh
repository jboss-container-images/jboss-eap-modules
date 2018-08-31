#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Add custom configuration file if one is not already present
# TODO remove this once streams using this module to provide this file (i.e. CD13)
# are no longer producing image updates
if [ ! -f "$JBOSS_HOME/standalone/configuration/standalone-openshift.xml" ]; then
  cp -p ${ADDED_DIR}/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/
fi

cp -p ${ADDED_DIR}/launch/* $JBOSS_HOME/bin/launch/
