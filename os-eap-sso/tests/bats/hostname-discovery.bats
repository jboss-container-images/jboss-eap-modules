#!/usr/bin/env bats

load common

# Runs the base api test
# {1} mock_response
function run_api_test {
    local mock_response=${1}
    local server_pid=$(setup_k8s_api ${mock_response})
    K8S_ENV=true
    local routes=$(discover_routes)
    pkill -P $server_pid
    echo $routes
}

@test "Is nc installed?" {
  run nc --version
  [ "$status" -eq 0 ]
}

@test "Kubernetes Route API not available" {
    local expected=""
    if [ "$K8S_ENV" = true ]; then
      skip "This test supposed to be run outside a kubernetes environment"
    fi
    run discover_routes
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "${expected}" ]
}

@test "Kubernetes Route API found no routes for the pod" {
    local expected=""
    local mock_response="no-route"
    result=$(run_api_test $mock_response)
    [ "${result}" = "$expected" ]
}

@test "Kubernetes Route API found one route for the pod" {
    local expected="https://eap-app-bsig-cloud.192.168.99.100.nip.io"
    local mock_response="single-route"
    result=$(run_api_test $mock_response)
    [ "${result}" = "$expected" ]
}

@test "Kubernetes Route API found multiple routes for the pod" {
    local expected="http://bc-authoring-rhpamcentr-bsig-cloud.192.168.99.100.nip.io;https://secure-bc-authoring-rhpamcentr-bsig-cloud.192.168.99.100.nip.io"
    local mock_response="multi-route"
    result=$(run_api_test $mock_response)
    [ "${result}" = "$expected" ]
}
