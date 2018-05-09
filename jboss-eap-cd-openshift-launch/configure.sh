#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Add custom configuration file
cp -p ${ADDED_DIR}/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/
# removes the default embedded broker
cp -p ${ADDED_DIR}/launch/messaging.sh $JBOSS_HOME/bin/launch/
