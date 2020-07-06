export JBOSS_HOME="${BATS_TMPDIR}/jboss_home"
# Prepare the directories and scripts to the right places
mkdir -p "${JBOSS_HOME}/bin/launch"
cp "${BATS_TEST_DIRNAME}/../added/partitionPV.sh" "${JBOSS_HOME}/bin/launch/"
cp "${BATS_TEST_DIRNAME}/../../../test-common/launch-common.sh" "${JBOSS_HOME}/bin/launch/"
cp "${BATS_TEST_DIRNAME}/../../../test-common/logging.sh" "${JBOSS_HOME}/bin/launch/"
# test files
cp "${BATS_TEST_DIRNAME}/test_queryosapi.py" "${JBOSS_HOME}/bin/launch/queryosapi.py"
chmod ugo+x "${JBOSS_HOME}/bin/launch/queryosapi.py"

# Set up the environment variables and load dependencies
source "${JBOSS_HOME}/bin/launch/launch-common.sh"
source "${JBOSS_HOME}/bin/launch/logging.sh"
# Sourcing the script for testing
source "${JBOSS_HOME}/bin/launch/partitionPV.sh"

# places to store the files needed for testing
export SERVER_TEMP_DIR="${BATS_TMPDIR}/server_temp_dir"
export SERVER_RUNNING_MARKER_FILENAME="server.was.started"

setup() {
  rm -rf "${SERVER_TEMP_DIR}"
}

# simulating the startup of the server; normally run by 'openshift-launch.sh' script
function runServer() {
  # expecting the first parameter to be set
  [ "x$1" = "x" ] && echo "The first parameter of meaning instanceDir has to be defined" && return 1
  touch "${1}/${SERVER_RUNNING_MARKER_FILENAME}"
  (
    echo "${I}: Running server with PID $$"
  )&
}

# function definition for testing purposes
function init_data_dir() {
  echo "init_data_dir executed"
}
