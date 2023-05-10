#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

mkdir -p ${JBOSS_HOME}/bin/launch
#Overwrite openshift-launch.sh

cp -p ${ADDED_DIR}/launch/* ${JBOSS_HOME}/bin/launch

#Ensure permissions
chmod -R g+rwX ${JBOSS_HOME}/bin/launch/
