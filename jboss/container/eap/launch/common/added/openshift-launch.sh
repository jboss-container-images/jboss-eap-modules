#!/bin/bash

echo "`date "+%Y-%m-%d %H:%M:%S"` Launching EAP Server"

# Always start sourcing the launch script supplied by wildfly-cekit-modules
source ${JBOSS_HOME}/bin/launch/launch.sh

# Append image specific modular options in standalone.conf
SPEC_VERSION="${JAVA_VERSION//1.}"
SPEC_VERSION="${SPEC_VERSION//.*}"
if (( $SPEC_VERSION > 15 )); then
  MODULAR_JVM_OPTIONS=`echo $JAVA_OPTS | grep "\-\-add\-modules"`
  if [ "x$MODULAR_JVM_OPTIONS" = "x" ]; then
    DIRNAME=`dirname "$0"`
    marker="#JVM modular options added by openshift startup script"
    if ! grep -q "$marker" "$DIRNAME/standalone.conf"; then
      jvm_options="$marker
JAVA_OPTS=\"\$JAVA_OPTS --add-exports=jdk.naming.dns/com.sun.jndi.dns=ALL-UNNAMED\""
     echo "$jvm_options" >> "$DIRNAME/standalone.conf"
    fi
  fi
fi
# end specific JDK modular options

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