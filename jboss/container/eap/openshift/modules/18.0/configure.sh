#!/bin/bash
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"

# Add new "openshift" layer
cp -rp --remove-destination "$ADDED_DIR/modules" "$JBOSS_HOME/"
chown -R jboss:root $JBOSS_HOME
chmod -R g+rwX $JBOSS_HOME
