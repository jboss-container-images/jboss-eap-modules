#!/bin/sh
# -------
# Handling start of application server with transaction recovery migration pod
#   it manages the safety of the transactions when object store can be touched
#   by application server and the migration pod
# -------

source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"

[ "x${SCRIPT_DEBUG}" = "xtrue" ] && DEBUG_QUERY_API_PARAM="-l debug"

# data should be placed to shared partition
IS_SPLIT_DATA_DEFINED=false
[ "${SPLIT_DATA^^}" = "TRUE" ] && IS_SPLIT_DATA_DEFINED=true
# saving recovery marker data to database
IS_TX_SQL_BACKEND=false
[ -n "${TX_DATABASE_PREFIX_MAPPING}" ] && IS_TX_SQL_BACKEND=true
[ "x$FORBID_TX_JDBC_RECOVERY_MARKER" = "xtrue" ] && IS_TX_SQL_BACKEND=false
if ! $IS_SPLIT_DATA_DEFINED && [ "x$FORBID_TX_JDBC_RECOVERY_MARKER" = "xtrue" ]; then
    log_warning "[`date`] Forbidden to use jdbc for recovery marker by use of variable FORBID_TX_JDBC_RECOVERY_MARKER while SPLIT_DATA is not enabled."
    log_warning "The transaction recovery marker algorithm is not capable to save recovery data and won't work."
fi
# module path as it's defined by driver binding of module.xml at jboss/container/eap/openshift/modules/added/modules/system/layers/openshift/io/narayana/openshift-recovery
JDBC_RECOVERY_DRIVER_OPENSHIFT_MODULE_PATH=${JDBC_RECOVERY_DRIVER_OPENSHIFT_MODULE_PATH:-"${JBOSS_HOME}/modules/system/layers/openshift/io/narayana/openshift-recovery/jdbc"}
# when not capable to connect to JDBC recovery storage retrying n-times before exiting the container
[[ $TX_JDBC_RECOVERY_CONNECTION_RETRY =~ ^[0-9]+$ ]] || TX_JDBC_RECOVERY_CONNECTION_RETRY=3

# parameters
# - needle to search in array
# - array passed as: "${ARRAY_VAR[@]}"
function arrContains() {
  local element match="$1"
  shift
  for element; do
    [[ "$element" == "$match" ]] && return 0
  done
  return 1
}

function init_pod_name() {
  # when POD_NAME is non-zero length using that given name

  # if the user specifies NODE_NAME or JBOSS_NODE_NAME - this is ONLY intended to be used by tests.
  [ -n "${NODE_NAME}" ] && POD_NAME="${NODE_NAME}"
  [ -n "${JBOSS_NODE_NAME}" ] && POD_NAME="${JBOSS_NODE_NAME}"
  # docker sets up container_uuid
  [ -z "${POD_NAME}" ] && POD_NAME="${container_uuid}"
  # openshift sets up the node id as host name
  [ -z "${POD_NAME}" ] && POD_NAME="${HOSTNAME}"

  # having set the POD_NAME is crucial as the migration process depends on unique identifier
  if [ -z "${POD_NAME}" ]; then
    log_error "[`date`] Cannot proceed further as failed to get unique POD_NAME as identifier of the server to be started"
    exit 1
  fi
}

# used to redefine starting jboss.node.name as identifier of jboss container
#   need to be restricted to 23 characters (CLOUD-427)
function truncate_jboss_node_name() {
  local NODE_NAME_TRUNCATED="$1"
  if [ ${#1} -gt 23 ]; then
    NODE_NAME_TRUNCATED=${1: -23}
  fi
  NODE_NAME_TRUNCATED=${NODE_NAME_TRUNCATED##-} # do not start the identifier with '-', it makes bash issues
  echo "${NODE_NAME_TRUNCATED}"
}

# parameters
# - base directory
function startApplicationServer() {
  local podsDir="$1"
  # 1) pods is available to start the application server
  init_pod_name

  local applicationPodDir="${podsDir}/${POD_NAME}"

  # allow this to be skipped if we're testing, or running in docker with no db etc.
  if [ "x${JDBC_SKIP_RECOVERY:-false}" != "xtrue" ]; then
    if $IS_TX_SQL_BACKEND; then
      initJdbcRecoveryMarkerProperties
      log_info "[`date`] Using database transaction recovery marker to be saved at ${JDBC_INFO}"
      # loop while waiting till the database recovery storage will be available
      local loopCount=0
      until createRecoveryDatabaseSchema; do
        if [ $loopCount -ge $TX_JDBC_RECOVERY_CONNECTION_RETRY ]; then
            log_error "[`date`] Tried to connect to ${JDBC_INFO} for ${TX_JDBC_RECOVERY_CONNECTION_RETRY} times without success. Exiting."
            exit 3
        fi
        log_error "[`date`] Cannot create schema of database transaction recovery records. Will be retrying."
        log_error "Trying to connect to database at ${JDBC_INFO} but is probably not available."
        loopCount=$((loopCount+1))
      done
    fi

    $IS_SPLIT_DATA_DEFINED && mkdir -p "${podsDir}"

    # 2) while any recovery marker matches, sleep and wait for recovery to finish
    local waitCounter=0
    while true; do
      if isRecoveryInProgress; then
        log_info "[`date`] Waiting to start pod ${POD_NAME} as recovery process for the pod is currently in progress"
      else
        # no recovery running: we are free to start the app container
        break
      fi
      sleep 1
    done
    # 3) create app server data directory with name of the pod name /or/ creating pod dir jdbc record
    if $IS_TX_SQL_BACKEND; then
      SERVER_DATA_DIR="${podsDir}"
      local applicationPodExistence=($(${JDBC_COMMAND_PODNAME_REGISTRY} select_application -a "${applicationPodDir}"))
      if [ "x${applicationPodExistence}" = "x" ]; then
        ${JDBC_COMMAND_PODNAME_REGISTRY} insert -a "${applicationPodDir}" -r 'undefined'
            if [ $? -ne 0 ]; then
                log_error "[`date`] Cannot insert transaction recovery marker into database ${JDBC_INFO}, pod ${applicationPodDir}. Exiting."
                exit 3
            fi
       fi
    fi
    if $IS_SPLIT_DATA_DEFINED; then
        SERVER_DATA_DIR="${applicationPodDir}/serverData"
        mkdir -p "${SERVER_DATA_DIR}"

        if [ ! -f "${SERVER_DATA_DIR}/../data_initialized" ]; then
           init_data_dir ${SERVER_DATA_DIR}
            touch "${SERVER_DATA_DIR}/../data_initialized"
        fi
    fi
  else
    echo "Skipping JDBC application server recovery start as JDBC_SKIP_RECOVERY is set to true"
  fi
  # 4) launch server with NODE_NAME to be assigned as POD_NAME (openshift-node-name.sh uses it)
  NODE_NAME=$(truncate_jboss_node_name "${POD_NAME}") runServer "${SERVER_DATA_DIR}" &

  PID=$!

  trap "echo Received TERM of pid ${PID} of pod name ${POD_NAME}; kill -TERM $PID" TERM

  wait $PID 2>/dev/null
  STATUS=$?
  trap - TERM
  wait $PID 2>/dev/null

  log_info "[`date`] Server terminated with status $STATUS ($(kill -l $STATUS 2>/dev/null))"

  if [ "$STATUS" -eq 255 ] ; then
    log_info "[`date`] Server returned 255, changing to 254"
    STATUS=254
  fi

  exit $STATUS
}

# parameters
# - base directory
# - migration pause between cycles
function migratePV() {
  local podsDir="$1"
  local applicationPodDir
  MIGRATION_PAUSE="${2:-30}"
  MIGRATED=false

  init_pod_name
  local recoveryPodName="${POD_NAME}"

  if $IS_TX_SQL_BACKEND; then
    initJdbcRecoveryMarkerProperties
    log_info "[`date`] Using database transaction recovery marker saved at ${JDBC_INFO}"
    until createRecoveryDatabaseSchema; do
      log_error "[`date`] Cannot create schema of recovery database records. Will be retrying."
      log_error "Database ${JDBC_INFO} is probably not available."
    done
  fi

  while true ; do

    if $IS_TX_SQL_BACKEND; then
      applicationPodDirs=($(${JDBC_COMMAND_PODNAME_REGISTRY} select_application))
    else
      unset applicationPodDirs
      declare -a applicationPodDirs
      for potentialApplicationPodDir in "${podsDir}"/*; do
          # check if the found file is type of directory, if not directory move to the next item
          [ ! -d "$potentialApplicationPodDir" ] && continue
          applicationPodDirs+=("$potentialApplicationPodDir")
      done
    fi

    # 1) Periodically, for each directory /pods/<applicationPodName> /or/ record in jdbc registry
    for applicationPodDir in "${applicationPodDirs[@]}"; do

      # 1.a) create the recovery marker
      local applicationPodName="$(basename ${applicationPodDir})"
      createRecoveryMarker "${podsDir}" "${applicationPodName}" "${recoveryPodName}"
      STATUS=42 # expecting there could be  error on getting living pods

      # 1.a.i) if <applicationPodName> is not in the cluster
      log_info "[`date`] Examining existence of living pod '${applicationPodName}'"
      unset LIVING_PODS
      LIVING_PODS=($($(dirname ${BASH_SOURCE[0]})/queryosapi.py -q pods_living -f list_space ${DEBUG_QUERY_API_PARAM}))
      [ $? -ne 0 ] && log_warning "[`date`] Can't get list of living pods" && continue
      # expecting the application pod of the same name was started/is living, it will manage recovery on its own
      local IS_APPLICATION_POD_LIVING=true
      if ! arrContains ${applicationPodName} "${LIVING_PODS[@]}"; then

        IS_APPLICATION_POD_LIVING=false

        (
          # 1.a.ii) run recovery until empty (including orphan checks and empty object store hierarchy deletion)
          MIGRATION_POD_TIMESTAMP=$(getPodLogTimestamp)  # investigating on current pod timestamp
          SERVER_DATA_DIR="${applicationPodDir}/serverData"
          NODE_NAME=$(truncate_jboss_node_name "${applicationPodName}") runMigration "${SERVER_DATA_DIR}" &

          PID=$!

          trap "echo Received TERM ; kill -TERM $PID" TERM

          wait $PID 2>/dev/null
          STATUS=$?
          trap - TERM
          wait $PID 2>/dev/null

          log_info "[`date`] Migration of pod ${applicationPodName} terminated with status $STATUS ($(kill -l $STATUS))"

          if [ "$STATUS" -eq 255 ] ; then
            log_info "[`date`] Server returned 255, changing to 254"
            STATUS=254
          fi
          exit $STATUS
        ) &

        PID=$!

        trap "kill -TERM $PID" TERM

        wait $PID 2>/dev/null
        STATUS=$?
        trap - TERM
        wait $PID 2>/dev/null

        if [ $STATUS -eq 0 ]; then
          # 1.a.iii) Delete /pods/<applicationPodName> directory /or/ jdbc registry record when recovery was succesful
          log_info "[`date`] Migration finished for pod name ${applicationPodName}, the record removed by recovery pod ${recoveryPodName}"
          if $IS_TX_SQL_BACKEND; then
            ${JDBC_COMMAND_PODNAME_REGISTRY} delete -a ${applicationPodDir}

            # removing not only recovery marker record but the narayana object store table too
            local podprefix="os${applicationPodName//-/}"
            local narayanasuffix="JBossTSTxTable"; # narayana does not exposes this value
            log_info "Dropping Narayana object store table '${podprefix}${narayanasuffix}'"
            ${JDBC_COMMAND_PODNAME_REGISTRY} drop -t "${podprefix}${narayanasuffix}"
          else
            rm -rf "${applicationPodDir}"
          fi
        fi
      fi

      # 1.b.) Deleting the recovery marker
      if [ $STATUS -eq 0 ] || [ $IS_APPLICATION_POD_LIVING ]; then
        # STATUS is 0: we are free from in-doubt transactions
        # IS_APPLICATION_POD_LIVING is true: there is a running pod of the same name, will do the recovery on his own, recovery pod won't manage it
        removeRecoveryMarker "${podsDir}" "${applicationPodName}" "${recoveryPodName}"
      fi

      # 2) checking for failed recovery pods to clean their data
      recoveryPodsGarbageCollection
    done

    log_info "[`date`] Finished migration check cycle, pausing for ${MIGRATION_PAUSE} seconds before resuming"
    MIGRATION_POD_TIMESTAMP=$(getPodLogTimestamp)
    trap 'kill $(jobs -p)' EXIT
    sleep "${MIGRATION_PAUSE}" & wait
    trap - EXIT
  done
}

# parameters
# - no params
function isRecoveryInProgress() {
  local isRecoveryInProgress=false
  if $IS_TX_SQL_BACKEND; then
    # jdbc based recovery descriptor
    recoveryMarkers=($(${JDBC_COMMAND_RECOVERY_MARKER} select_recovery -a ${POD_NAME}))
    local isRecoveryInProgress=false
    [ ${#recoveryMarkers[@]} -ne 0 ] && isRecoveryInProgress=true # array is not empty, there are recovery markers existing
  fi
  if $IS_SPLIT_DATA_DEFINED; then
    # shared file system based recovery descriptor
    find "${podsDir}" -maxdepth 1 -type f -name "${POD_NAME}-RECOVERY-*" 2>/dev/null | grep -q .
    # is there an existing RECOVERY descriptor that means a recovery is in progress
    [ $? -eq 0 ] && isRecoveryInProgress=true
  fi
  $isRecoveryInProgress && return 0 || return 1
}

# parameters
# - place where pod data directories are saved
# - application pod name
# - recovery pod name
function createRecoveryMarker() {
  local podsDir="${1}"
  local applicationPodName="${2}"
  local recoveryPodName="${3}"

  if $IS_TX_SQL_BACKEND; then
    # jdbc recovery marker insertion
    ${JDBC_COMMAND_RECOVERY_MARKER} insert -a ${applicationPodName} -r ${recoveryPodName}
  else
    # file system recovery marker creation: /pods/<applicationPodName>-RECOVERY-<recoveryPodName>
    touch "${podsDir}/${applicationPodName}-RECOVERY-${recoveryPodName}"
    sync
  fi
}

# parameters
# - place where pod data directories are saved (podsDir)
# - application pod name
# - recovery pod name
function removeRecoveryMarker() {
  local podsDir="${1}"
  local applicationPodName="${2}"
  local recoveryPodName="${3}"

  if $IS_TX_SQL_BACKEND; then
    # jdbc recovery marker removal
    ${JDBC_COMMAND_RECOVERY_MARKER} delete -a ${applicationPodName} -r ${recoveryPodName}
  else
    # file system recovery marker deletion
    rm -f "${podsDir}/${applicationPodName}-RECOVERY-${recoveryPodName}"
    sync
  fi
}

# parameters:
# - place where pod data directories are saved (podsDir)
function recoveryPodsGarbageCollection() {
  local livingPods=($($(dirname ${BASH_SOURCE[0]})/queryosapi.py -q pods_living -f list_space ${DEBUG_QUERY_API_PARAM}))
  if [ $? -ne 0 ]; then # fail to connect to openshift api
    log_warning "[`date`] Can't get list of living pods. Can't do recovery marker garbage collection."
    return 1
  fi

  if $IS_TX_SQL_BACKEND; then
    # jdbc
    local recoveryMarkers=($(${JDBC_COMMAND_RECOVERY_MARKER} select_recovery))
    for recoveryPod in "${recoveryMarkers[@]}"; do
      if ! arrContains ${recoveryPod} "${livingPods[@]}"; then
        # recovery pod is dead, garbage collecting
        ${JDBC_COMMAND_RECOVERY_MARKER} delete -r ${recoveryPod}
      fi
    done
  else
    # file system
    for recoveryPodFilePathToCheck in "${podsDir}/"*-RECOVERY-*; do
      local recoveryPodFileToCheck="$(basename ${recoveryPodFilePathToCheck})"
      local recoveryPodNameToCheck=${recoveryPodFileToCheck#*RECOVERY-}
      if ! arrContains ${recoveryPodNameToCheck} "${livingPods[@]}"; then
        # recovery pod is dead, garbage collecting
        rm -f "${recoveryPodFilePathToCheck}"
      fi
    done
  fi
}


# parameters
# - pod name (optional)
function getPodLogTimestamp() {
  init_pod_name
  local podNameToProbe=${1:-$POD_NAME}

  local logOutput=$($(dirname ${BASH_SOURCE[0]})/queryosapi.py -q log --pod ${podNameToProbe} --tailline 1 ${DEBUG_QUERY_API_PARAM})
  # only one, last line of the log, is returned, taking the start which is timestamp
  echo $logOutput | sed 's/ .*$//'
}

# parameters
# - since time (when the pod listing start at)
# - pod name (optional)
function probePodLogForRecoveryErrors() {
  init_pod_name
  local sinceTimestampParam=''
  local sinceTimestamp=${1:-$MIGRATION_POD_TIMESTAMP}
  [ "x$sinceTimestamp" != "x" ] && sinceTimestampParam="--sincetime ${sinceTimestamp}"
  local podNameToProbe=${2:-$POD_NAME}

  local logOutput=$($(dirname ${BASH_SOURCE[0]})/queryosapi.py -q log --pod ${podNameToProbe} ${sinceTimestampParam} ${DEBUG_QUERY_API_PARAM})
  local probeStatus=$?

  if [ $probeStatus -ne 0 ]; then
    log_warning "[`date`] Cannot contact OpenShift API to get log for pod ${podNameToProbe}"
    return 1
  fi

  local isPeriodicRecoveryError=false
  local patternToCheck="ERROR.*Periodic Recovery"
  # even for debug it's too verbose to print this pattern checking
  [ "x${SCRIPT_DEBUG}" = "xtrue" ] && set +x
  while read line; do
    [[ $line =~ $patternToCheck ]] && isPeriodicRecoveryError=true && break
  done <<< "$logOutput"
  [ "x${SCRIPT_DEBUG}" = "xtrue" ] && set -x

  if $isPeriodicRecoveryError; then # ERROR string was found in the log output
    log_warning "[`date`] Pod '${podNameToProbe}' started with periodic recovery errors: '$line'"
    return 1
  fi

  return 0
}

# parameters:
# - no params
function initJdbcRecoveryMarkerProperties() {
  tx_backend=${TX_DATABASE_PREFIX_MAPPING}

  service_name=${tx_backend%=*}
  service=${service_name^^}
  service=${service//-/_}
  db=${service##*_}
  prefix=${tx_backend#*=}

  JDBC_RECOVERY_DB_HOST=$(find_env "${service}_SERVICE_HOST")
  JDBC_RECOVERY_DB_PORT=$(find_env "${service}_SERVICE_PORT")
  JDBC_RECOVERY_DATABASE=$(find_env "${prefix}_DATABASE")
  JDBC_RECOVERY_USER=$(find_env "${prefix}_USERNAME")
  JDBC_RECOVERY_PASSWORD=$(find_env "${prefix}_PASSWORD")
  JDBC_RECOVERY_URL=$(find_env "${prefix}_URL")
  JDBC_RECOVERY_DATABASE_TYPE=$(find_env "${prefix}_DATABASE_TYPE")
  JDBC_RECOVERY_HIBERNATE_DIALECT=$(find_env "${prefix}_HIBERNATE_DIALECT")
  JDBC_RECOVERY_JDBC_DRIVER_CLASS=$(find_env "${prefix}_JDBC_DRIVER_CLASS")
  JDBC_RECOVERY_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

  local jdbcTableSuffix=${TX_JDBC_RECOVERY_MARKER_TABLE_SUFFIX//-/}
  [ "x${jdbcTableSuffix}" != "x" ] && jdbcTableSuffix="_${jdbcTableSuffix}"
  JDBC_RECOVERY_TABLE="recmark${jdbcTableSuffix}"
  JDBC_PODNAME_REGISTRY_TABLE="recpodreg${jdbcTableSuffix}"

  if [ "x${JDBC_RECOVERY_DATABASE_TYPE}" = "x" ]; then
    JDBC_RECOVERY_DATABASE_TYPE=$(getDbType "$db")
  fi

  createCustomJDBCDriverModuleAlias

  JDBC_INFO="${JDBC_RECOVERY_URL}"
  [ -z "${JDBC_INFO}" ] && JDBC_INFO="${JDBC_RECOVERY_DB_HOST}:${JDBC_RECOVERY_DB_PORT}/${JDBC_RECOVERY_DATABASE}"

   if ( [ -z $JDBC_RECOVERY_URL ] ) &&\
      ( [ -z $JDBC_RECOVERY_USER ] || [ -z $JDBC_RECOVERY_PASSWORD ] || [ -z $JDBC_RECOVERY_DB_HOST ] || [ -z $JDBC_RECOVERY_DB_PORT ] || [ -z $JDBC_RECOVERY_DATABASE ] ); then
     log_warning "There is a problem with the databse ${db,,} setup!"
     log_warning "In order to create transaction recovery database tables for $prefix service you need to provide following environment variables: ${service}_SERVICE_HOST, ${service}_SERVICE_PORT, ${prefix}_USERNAME, ${prefix}_PASSWORD, ${prefix}_DATABASE or ${prefix}_URL."
     log_warning
     log_warning "Current values:"
     log_warning "${service}_SERVICE_HOST: $JDBC_RECOVERY_DB_HOST"
     log_warning "${service}_SERVICE_PORT: $JDBC_RECOVERY_DB_PORT"
     log_warning "${prefix}_USERNAME: $JDBC_RECOVERY_USER"
     log_warning "${prefix}_PASSWORD: $JDBC_RECOVERY_PASSWORD"
     log_warning "${prefix}_DATABASE: $JDBC_RECOVERY_DATABASE"
     log_warning "${prefix}_URL: $JDBC_RECOVERY_URL"
     log_warning "${prefix}_DATABASE_TYPE: $JDBC_RECOVERY_DATABASE_TYPE"
     log_warning "${prefix}_HIBERNATE_DIALECT: $JDBC_RECOVERY_HIBERNATE_DIALECT"
     log_warning "${prefix}_JDBC_DRIVER_CLASS: $JDBC_RECOVERY_JDBC_DRIVER_CLASS"
     log_warning
     log_error   "The image startup could fail. For disabling transaction database scaledown processing do NOT use property TX_DATABASE_PREFIX_MAPPING."
   fi

  LOGGING_PROPERTIES="-Djava.util.logging.config.file=$(dirname ${BASH_SOURCE[0]})/logging.properties"
  # do not reduce logging when debug is enabled
  [ "x${SCRIPT_DEBUG}" = "xtrue" ] && LOGGING_PROPERTIES=""

  local jopts=""
  if [ -n "$GALLEON_MAVEN_SETTINGS_XML" ]; then
    jopts="-Djboss.modules.settings.xml.url=file://$GALLEON_MAVEN_SETTINGS_XML"
  fi

  # one table works as storage for recovery markers, other stores information about started pods
  local jdbcCommand="java $jopts $LOGGING_PROPERTIES -jar $JBOSS_HOME/jboss-modules.jar -mp $JBOSS_HOME/modules/ io.narayana.openshift-recovery -u ${JDBC_RECOVERY_USER} -s ${JDBC_RECOVERY_PASSWORD}"
  [ "x${JDBC_RECOVERY_DATABASE_TYPE}" != "x" ] && jdbcCommand="$jdbcCommand -y ${JDBC_RECOVERY_DATABASE_TYPE}"
  [ "x${JDBC_RECOVERY_URL}" != "x" ] && jdbcCommand="$jdbcCommand -l ${JDBC_RECOVERY_URL}"
  [ "x${JDBC_RECOVERY_DB_HOST}" != "x" ] && jdbcCommand="$jdbcCommand -o ${JDBC_RECOVERY_DB_HOST}"
  [ "x${JDBC_RECOVERY_DB_PORT}" != "x" ] && jdbcCommand="$jdbcCommand -p ${JDBC_RECOVERY_DB_PORT}"
  [ "x${JDBC_RECOVERY_DATABASE}" != "x" ] && jdbcCommand="$jdbcCommand -d ${JDBC_RECOVERY_DATABASE}"
  [ "x${JDBC_RECOVERY_HIBERNATE_DIALECT}" != "x" ] && jdbcCommand="$jdbcCommand -i ${JDBC_RECOVERY_HIBERNATE_DIALECT}"
  [ "x${JDBC_RECOVERY_JDBC_DRIVER_CLASS}" != "x" ] && jdbcCommand="$jdbcCommand -j ${JDBC_RECOVERY_JDBC_DRIVER_CLASS}"
  JDBC_COMMAND_RECOVERY_MARKER="${jdbcCommand} -t ${JDBC_RECOVERY_TABLE} -c"
  JDBC_COMMAND_PODNAME_REGISTRY="${jdbcCommand} -t ${JDBC_PODNAME_REGISTRY_TABLE} -c"
}

# creating the database schema
# parameters:
# - no params, expected to be called after the init properties is invoked
function createRecoveryDatabaseSchema() {
  ${JDBC_COMMAND_RECOVERY_MARKER} create
  [ $? -ne 0 ] && return 1
  ${JDBC_COMMAND_PODNAME_REGISTRY} create
  [ $? -ne 0 ] && return 1
  return 0
}

# creating a new jboss module named 'io.narayana.openshift-recovery.jdbc'
# which aliases the specified JDBC driver module name.
# The 'io.narayana.openshift-recovery.jdbc' is module name used when searching for custom JDBC drivers.
# This method aliases the existing JDBC driver jboss module to the narayana one that recovery uses.
# If user has defined e.g. an Oracle driver module 'com.oracle.ojdbc' he may specify that's the module
# where scaledown recovery finds the driver class, ie. via JDBC_RECOVERY_CUSTOM_JDBC_MODULE=com.oracle.ojdbc
function createCustomJDBCDriverModuleAlias() {
  if [ "x${JDBC_RECOVERY_CUSTOM_JDBC_MODULE}" = "x" ]; then
    return
  fi

  local TARGET_MODULE_PATH_DIR="${JDBC_RECOVERY_DRIVER_OPENSHIFT_MODULE_PATH}/main"
  mkdir -p "${TARGET_MODULE_PATH_DIR}"
  echo "<module-alias xmlns=\"urn:jboss:module:1.9\" name=\"io.narayana.openshift-recovery.jdbc\" target-name=\"${JDBC_RECOVERY_CUSTOM_JDBC_MODULE}\"/>" > "${TARGET_MODULE_PATH_DIR}/module.xml"
}

# returns database type string which is recognized by the jbosstm/narayana-openshift-tools,
# represented as jars placed at jboss module io.narayana.openshift-recovery
# parameters:
# - db type which should be converted to the string understandable by java program
function getDbType() {
  case "$1" in
    "MYSQL")
      echo 'mysql'
      return 0
      ;;
    "POSTGRESQL")
      echo 'postgresql'
      return 0
      ;;
    "ORACLE")
      echo 'oracle'
      return 0
      ;;
    "DB2")
      echo 'db2'
      return 0
      ;;
    "SYBASE")
      echo 'sybase'
      return 0
      ;;
    "MARIADB")
      echo 'mariadb'
      return 0
      ;;
    "SYBASE")
      echo 'sybase'
      return 0
      ;;
    "MSSQL")
      echo 'mssql'
      return 0
      ;;
    "POSTGRESPLUS")
      echo 'postgresplus'
      return 0
      ;;
  esac
  log_warning "[`date`] There is not defined variable '${prefix}_DATABASE_TYPE' and the PREFIX part of the TX_DATABASE_PREFIX_MAPPING='${TX_DATABASE_PREFIX_MAPPING}' does not contain information on database type."
  log_warning "  Consider to configure the variable '${prefix}_DATABASE_TYPE' with string like: 'mysql', 'oracle', 'postgresql', ..."
  echo ""
  return 1
}