#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

#Overwrite openshift-common-launch
cp -p ${ADDED_DIR}/openshift-common.sh ${JBOSS_HOME}/bin/launch/openshift-common.sh

#Ensure permissions
chown -R jboss:root ${JBOSS_HOME}/bin/
chmod -R g+rwX ${JBOSS_HOME}/bin/launch/
