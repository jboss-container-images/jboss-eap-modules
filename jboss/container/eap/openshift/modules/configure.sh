#!/bin/bash
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"
VERSION_TXN_MARKER="1.1.4.Final-redhat-00001"

# Add new "openshift" layer
cp -rp --remove-destination "$ADDED_DIR/modules" "$JBOSS_HOME/"

cp -p "${SOURCES_DIR}/txn-recovery-marker-jdbc-common-${VERSION_TXN_MARKER}.jar" "$JBOSS_HOME/modules/system/layers/openshift/io/narayana/openshift-recovery/main/txn-recovery-marker-jdbc-common.jar"
cp -p "${SOURCES_DIR}/txn-recovery-marker-jdbc-hibernate5-${VERSION_TXN_MARKER}.jar" "$JBOSS_HOME/modules/system/layers/openshift/io/narayana/openshift-recovery/main/txn-recovery-marker-jdbc-hibernate5.jar"

chown -R jboss:root $JBOSS_HOME
chmod -R g+rwX $JBOSS_HOME
