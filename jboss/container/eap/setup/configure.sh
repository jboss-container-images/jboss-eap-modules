#!/bin/sh
# Configure module
set -e
SCRIPT_DIR=$(dirname $0)
ARTIFACTS_DIR=${SCRIPT_DIR}/artifacts

# Create empty JBOSS_HOME and needed directories for other modules to install content.
mkdir -p $JBOSS_HOME/bin/launch
mkdir -p ${JBOSS_HOME}/standalone/deployments/

# Add standalone.conf
cp -r ${ARTIFACTS_DIR}/* ${JBOSS_HOME}