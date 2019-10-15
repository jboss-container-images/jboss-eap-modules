#!/bin/sh
# Configure module
set -e

# Create empty JBOSS_HOME and needed directories for other modules to install content.
mkdir -p $JBOSS_HOME/bin/launch
mkdir -p ${JBOSS_HOME}/standalone/deployments/