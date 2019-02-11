#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"
LOGMANAGER_JAR="jboss-logmanager-2.1.7.Final.jar"
LAYER=openshift

. $JBOSS_HOME/bin/launch/files.sh

JBOSS_LOGGING_JAR="$(getfiles org/jboss/logging/main/jboss-logging)"
JBOSS_LOGGING_DIR="$(dirname $JBOSS_LOGGING_JAR)"

# Location to install the new module
OPENSHIFT_LAYER_PATH="${JBOSS_HOME}/modules/system/layers/${LAYER}/org/jboss/logmanager/main/"

mkdir -p $OPENSHIFT_LAYER_PATH
# rm old jar
rm -rf $OPENSHIFT_LAYER_PATH/*.jar
cp -p ${SOURCES_DIR}/${LOGMANAGER_JAR} $OPENSHIFT_LAYER_PATH
cp -p ${ADDED_DIR}/module.xml $OPENSHIFT_LAYER_PATH
