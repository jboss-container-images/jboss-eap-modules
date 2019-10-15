#!/bin/sh
# Configure module
set -e

CONTENT_DIR=$JBOSS_CONTAINER_EAP_GALLEON_FP_PACKAGES/eap.s2i.amq6.rar/content/standalone/deployments
mkdir -p $CONTENT_DIR
cp $JBOSS_HOME/standalone/deployments/activemq-rar.rar $CONTENT_DIR
rm $JBOSS_HOME/standalone/deployments/activemq-rar.rar
