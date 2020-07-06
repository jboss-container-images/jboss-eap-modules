#!/usr/bin/env bats

load common

@test "arrContains: find existing item" {
    ARRAY_TO_TEST=( itemone itemtwo itemthree )
    run arrContains itemtwo "${ARRAY_TO_TEST[@]}"
    [ "$status" -eq 0 ]
}

@test "arrContains: fail with non existing item" {
    ARRAY_TO_TEST=( itemone itemtwo itemthree )
    run arrContains itemfour "${ARRAY_TO_TEST[@]}"
    [ "$status" -eq 1 ]
}

@test "init_pod_name: NODE_NAME specified" {
    NODE_NAME="nodename"
    init_pod_name
    [ "$?" -eq 0 ]
    [ "$POD_NAME" = "$NODE_NAME" ]
}

@test "init_pod_name: JBOSS_NODE_NAME overrides the pod name value" {
    NODE_NAME="nodename"
    JBOSS_NODE_NAME="jbossnodename"
    init_pod_name
    [ "$?" -eq 0 ]
    [ "$POD_NAME" = "$JBOSS_NODE_NAME" ]
}

@test "init_pod_name: uses the host name or docker container uuid" {
    init_pod_name
    [ "$?" -eq 0 ]
    [ "$POD_NAME" = "$HOSTNAME" ] || [ "$POD_NAME" = "${container_uuid}" ]
}

@test "truncate_jboss_node_name: long name has to be truncated up to 23 characters not started with -" {
    CHARACTERS_22_LONG="ABCDEFGHIJKLMNOPQRSTUV"
    run truncate_jboss_node_name "moreCharatersHere#-${CHARACTERS_22_LONG}"
    [ "$status" -eq 0 ]
    [ "$output" = "${CHARACTERS_22_LONG}" ]
}

# Server is started with data directory which is passed to the function in parameter
@test "startApplicationServer: simple start, no split data dir" {
    export IS_TX_SQL_BACKEND=false
    export IS_SPLIT_DATA_DEFINED=false

    SERVER_DATA_DIR="$SERVER_TEMP_DIR"
    mkdir -p "$SERVER_DATA_DIR"

    POD_NAME="node-name-1"
    run startApplicationServer
    [ "$status" -eq 0 ]
    [ -f "${SERVER_DATA_DIR}/${SERVER_RUNNING_MARKER_FILENAME}" ]
}

# Definition of the split data expects that multiple servers share the same directory for their runtime data
# The startup script has to create separate place for each server
@test "startApplicationServer: split data dir defined, no recovery" {
    IS_TX_SQL_BACKEND=false
    IS_SPLIT_DATA_DEFINED=true
    POD_NAME="node-name-split-data"

    run startApplicationServer "${SERVER_TEMP_DIR}"
    [ "$status" -eq 0 ]
    [ -f "${SERVER_TEMP_DIR}/${POD_NAME}/serverData/${SERVER_RUNNING_MARKER_FILENAME}" ]
    [ -f "${SERVER_TEMP_DIR}/${POD_NAME}/data_initialized" ]
}

# The test simulates the recovery in progress
# the recovery processing creates a marker file with the name
# the test creates the marker file with the name of the pod which is about to be started
# the application server is started only after the recovery marker is removed
@test "startApplicationServer: split data dir defined, recovery in progress" {
    IS_TX_SQL_BACKEND=false
    IS_SPLIT_DATA_DEFINED=true
    POD_NAME="node-name-with-recovery"
    mkdir -p "${SERVER_TEMP_DIR}"
    local recoveryMarkerFileName="${SERVER_TEMP_DIR}/${POD_NAME}-RECOVERY-bats.testing"

    touch "$recoveryMarkerFileName"

    startApplicationServer "${SERVER_TEMP_DIR}" &
    local startApplicationServerPid=$!
    sleep "0.01"

    [ ! -f "${SERVER_TEMP_DIR}/${POD_NAME}/serverData/${SERVER_RUNNING_MARKER_FILENAME}" ]
    rm -f "$recoveryMarkerFileName"

    wait $startApplicationServerPid
    echo ":: $(kill -0 $testPid)"

    [ -f "${SERVER_TEMP_DIR}/${POD_NAME}/serverData/${SERVER_RUNNING_MARKER_FILENAME}" ]
    [ -f "${SERVER_TEMP_DIR}/${POD_NAME}/data_initialized" ]
}

@test "recovery marker creation and deletion" {
    IS_TX_SQL_BACKEND=false
    IS_SPLIT_DATA_DEFINED=true
    POD_NAME="recovery-in-progress"
    mkdir -p "${SERVER_TEMP_DIR}"
    podsDir="${SERVER_TEMP_DIR}"

    if isRecoveryInProgress "${SERVER_TEMP_DIR}"; then
        # recovery in progress expected to fail
        return 1
    fi

    createRecoveryMarker "${SERVER_TEMP_DIR}" "${POD_NAME}" "recovery-name"
    isRecoveryInProgress "${SERVER_TEMP_DIR}"
    removeRecoveryMarker "${SERVER_TEMP_DIR}" "${POD_NAME}" "recovery-name"

    if isRecoveryInProgress "${SERVER_TEMP_DIR}"; then
        # recovery in progress #2 expected to fail
        return 1
    fi
}

@test "recovery garbage collection cleanup" {
    IS_TX_SQL_BACKEND=false
    IS_SPLIT_DATA_DEFINED=true
    POD_NAME="recovery-garbage-collection"
    local recoveryMarkerName="recovery-name"
    mkdir -p "${SERVER_TEMP_DIR}"
    podsDir="${SERVER_TEMP_DIR}"

    run recoveryPodsGarbageCollection "${SERVER_TEMP_DIR}"
    [ "$status" -eq 0 ]

    createRecoveryMarker "${SERVER_TEMP_DIR}" "${POD_NAME}" $recoveryMarkerName
    [ -f "${SERVER_TEMP_DIR}/${POD_NAME}-RECOVERY-${recoveryMarkerName}" ]

    run recoveryPodsGarbageCollection "${SERVER_TEMP_DIR}"
    [ "$status" -eq 0 ]
    [ ! -f "${SERVER_TEMP_DIR}/${POD_NAME}-RECOVERY-${recoveryMarkerName}" ]
}