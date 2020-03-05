#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

# Add jolokia specific scripts
cp -r "$ADDED_DIR"/* $JBOSS_HOME/bin/

chown -R jboss:root $JBOSS_HOME/bin/
chmod -R g+rwX $JBOSS_HOME/bin/
