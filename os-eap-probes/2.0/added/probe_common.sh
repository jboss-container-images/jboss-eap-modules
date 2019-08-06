#!/bin/sh
# common routines for readiness and liveness probes

# jboss-cli.sh sometimes hangs indefinitely. Send SIGTERM after CLI_TIMEOUT has passed
# and failing that SIGKILL after CLI_KILLTIME, to ensure that it exits
CLI_TIMEOUT=10s
CLI_KILLTIME=30s

EAP_7_WARNING="Warning! The CLI is running in a non-modular environment and cannot load commands from management extensions."

run_cli_cmd() {
    cmd="$1"

    #Default for EAP7
    cli_port=9990
    
    if [ -f "$JBOSS_HOME/bin/run.sh" ]; then
      version=$($JBOSS_HOME/bin/run.sh -V)
      if [[ "$version" == *"JBoss Enterprise Application Platform 6"* ]]; then
        cli_port=9999
      fi
    fi

    if [ -n "${PORT_OFFSET}" ]; then
      cli_port=$(($cli_port+$PORT_OFFSET))
    fi

    timeout --foreground -k "$CLI_KILLTIME" "$CLI_TIMEOUT" java -jar $JBOSS_HOME/bin/client/jboss-cli-client.jar --connect --controller=localhost:${cli_port} "$cmd" | grep -v "$EAP_7_WARNING"
}

is_eap7() {
    run_cli_cmd "version" | grep -q "^JBoss AS product: JBoss EAP 7"
}

# Additional check necessary for EAP7, see CLOUD-615
deployments_failed() {
    ls -- /deployments/*failed >/dev/null 2>&1 || (is_eap7 && run_cli_cmd "deployment-info" | grep -q FAILED)
}

list_failed_deployments() {
    ls -- /deployments/*failed >/dev/null 2>&1 && \
        echo /deployments/*.failed | sed "s+^/deployments/\(.*\)\.failed$+\1+"
}

is_ocp4_or_greater() {
  CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  SERVICE_PORT="${KUBERNETES_SERVICE_PORT:-443}"
  SERVICE_HOST="${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}"
  VERSION_URL="https://${SERVICE_HOST}:${SERVICE_PORT}/version"

  if [ -f "${CA_CERT}" ]; then
    CURL_CERT_OPTION="--cacert ${CA_CERT}"
  else
    CURL_CERT_OPTION="-k"
  fi

  VERSION=$(curl -s ${CURL_CERT_OPTION} "${VERSION_URL}" | python -c 'import sys, json; a=json.load(sys.stdin); print("%s.%s" % (a["major"], a["minor"]))')
  IFS=. read -r maj min <<< "${VERSION}"
  # drop '+' if it's present in min
  min=${min%+}
  if [ "${maj:-0}" -ge 1 ]; then
    if [ "${min:-0}" -ge 13 ]; then
      echo "true"
      export OCP4="true"
      return
    fi
  fi
  echo "false"
  export OCP4="false"
}
