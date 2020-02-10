#!/bin/bash

# Always start sourcing the launch script supplied by wildfly-cekit-modules
source ${JBOSS_HOME}/bin/launch/launch.sh

function runServer() {
  local instanceDir=$1
  launchServer "$JBOSS_HOME/bin/standalone.sh -c standalone-openshift.xml -bmanagement 0.0.0.0 -Djboss.server.data.dir=${instanceDir} -Dwildfly.statistics-enabled=true"
}

function init_data_dir() {
  local DATA_DIR="$1"
  if [ -d "${JBOSS_HOME}/standalone/data" ]; then
    cp -rf ${JBOSS_HOME}/standalone/data/* $DATA_DIR
  fi
}


if [ "${SPLIT_DATA^^}" = "TRUE" ]; then
  # SPLIT_DATA defines shared volume for multiple pods mounted at partitioned_data where server saves data
  #  migration pod is started to supervise the shared volume and cleaning it
  source /opt/partition/partitionPV.sh

  DATA_DIR="${JBOSS_HOME}/standalone/partitioned_data"

  startApplicationServer "${DATA_DIR}" "${SPLIT_LOCK_TIMEOUT:-30}"
elif [ -n "${TX_DATABASE_PREFIX_MAPPING}" ]; then
  # TX_DATABASE_PREFIX_MAPPING defines to save object store data into database
  #  migration pod for to clean in-doubt transactions is started, saving data to the same database
  source /opt/partition/partitionPV.sh

  DATA_DIR="${JBOSS_HOME}/standalone/data"

  startApplicationServer "${DATA_DIR}" "${SPLIT_LOCK_TIMEOUT:-30}"
else
  # no migration pod is run

  runServer "${JBOSS_HOME}/standalone/data"

fi