
if [ -n "${NODE_NAME_INCLUDE}" ]; then
    source "${NODE_NAME_INCLUDE}"
else
    source ${JBOSS_HOME}/bin/launch/openshift-node-name.sh
fi

if [ -n "${LOGGING_INCLUDE}" ]; then
    source "${LOGGING_INCLUDE}"
else
  source $JBOSS_HOME/bin/launch/logging.sh
fi

prepareEnv() {
  unset OPENSHIFT_KUBE_PING_NAMESPACE
  unset OPENSHIFT_KUBE_PING_LABELS
  unset OPENSHIFT_DNS_PING_SERVICE_NAME
  unset OPENSHIFT_DNS_PING_SERVICE_PORT
  unset JGROUPS_CLUSTER_PASSWORD
  unset JGROUPS_PING_PROTOCOL
  unset NODE_NAME
  unset KUBERNETES_NAMESPACE
  unset KUBERNETES_LABELS
}

configure() {
  configure_ha
}

check_view_pods_permission() {
    if [ -n "${OPENSHIFT_KUBE_PING_NAMESPACE+_}" ] || [ -n "${KUBERNETES_NAMESPACE}" ]; then
        local CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        local CURL_CERT_OPTION
        local namespace="${KUBERNETES_NAMESPACE:-${OPENSHIFT_KUBE_PING_NAMESPACE}}"
        local labels="${KUBERNETES_LABELS:-${OPENSHIFT_KUBE_PING_LABELS}}"
        local api_version="${OPENSHIFT_KUBE_PING_API_VERSION:-v1}"
        local service_port="${KUBERNETES_SERVICE_PORT:-443}"
        local service_host="${KUBERNETES_SERVICE_HOST:-kubernetes.default.svc}"

        pods_url="https://${service_host}:${service_port}/api/${api_version}/namespaces/${namespace}/pods"
        if [ -n "${labels}" ]; then
            pods_labels="labels=${labels}"
        else
            pods_labels=""
        fi

        # make sure the cert exists otherwise use insecure connection
        if [ -f "${CA_CERT}" ]; then
            CURL_CERT_OPTION="--cacert ${CA_CERT}"
        else
            CURL_CERT_OPTION="-k"
        fi
        pods_auth="Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
        pods_code=$(curl --noproxy "*" -s -o /dev/null -w "%{http_code}" -G --data-urlencode "${pods_labels}" ${CURL_CERT_OPTION} -H "${pods_auth}" ${pods_url})
        if [ "${pods_code}" = "200" ]; then
            log_info "Service account has sufficient permissions to view pods in kubernetes (HTTP ${pods_code}). Clustering will be available."
        elif [ "${pods_code}" = "403" ]; then
            log_warning "Service account has insufficient permissions to view pods in kubernetes (HTTP ${pods_code}). Clustering might be unavailable. Please refer to the documentation for configuration."
        else
            log_warning "Service account unable to test permissions to view pods in kubernetes (HTTP ${pods_code}). Clustering might be unavailable. Please refer to the documentation for configuration."
        fi
    else
        log_warning "Environment variable OPENSHIFT_KUBE_PING_NAMESPACE undefined. Clustering will be unavailable. Please refer to the documentation for configuration."
    fi
}

validate_dns_ping_settings() {
  if [ "x$OPENSHIFT_DNS_PING_SERVICE_NAME" = "x" ]; then
    log_warning "Environment variable OPENSHIFT_DNS_PING_SERVICE_NAME undefined. Clustering will be unavailable. Please refer to the documentation for configuration."
  fi
}

validate_ping_protocol() {
  declare protocol="$1"
  if [ "${protocol}" = "openshift.KUBE_PING" ] || [ "${protocol}" = "kubernetes.KUBE_PING" ]; then
    check_view_pods_permission
  elif [ "${protocol}" = "openshift.DNS_PING" ]; then
    validate_dns_ping_settings
  else
    log_warning "Unknown protocol specified for JGroups discovery protocol: $1. Expecting one of: kubernetes.KUBE_PING, openshift.KUBE_PING or openshift.DNS_PING."
  fi
}

get_socket_binding_for_ping() {
    # KUBE_PING and DNS_PING don't need socket bindings, but if the protocol is something else, we should allow it
    declare protocol="$1"
    if [ "${protocol}" = "openshift.KUBE_PING" -o \
          "${protocol}" = "openshift.DNS_PING" -o \
          "${protocol}" = "kubernetes.KUBE_PING" -o \
          "${protocol}" = "dns.DNS_PING" ]; then
        echo ""
    else
        echo "socket-binding=\"jgroups-mping\""
    fi
}
configure_ha() {
  # Set HA args
  IP_ADDR=`hostname -i`
  JBOSS_HA_ARGS="-b ${JBOSS_HA_IP:-${IP_ADDR}} -bprivate ${JBOSS_HA_IP:-${IP_ADDR}}"

  init_node_name

  JBOSS_HA_ARGS="${JBOSS_HA_ARGS} -Djboss.node.name=${JBOSS_NODE_NAME}"

  if [ -z "${JGROUPS_CLUSTER_PASSWORD}" ]; then
      log_warning "No password defined for JGroups cluster. AUTH protocol will be disabled. Please define JGROUPS_CLUSTER_PASSWORD."
      JGROUPS_AUTH="<!--WARNING: No password defined for JGroups cluster. AUTH protocol has been disabled. Please define JGROUPS_CLUSTER_PASSWORD. -->"
  else
    JGROUPS_AUTH="\n\
                <auth-protocol type=\"AUTH\">\n\
                    <digest-token algorithm=\"${JGROUPS_DIGEST_TOKEN_ALGORITHM:-SHA-512}\">\n\
                        <shared-secret-reference clear-text=\"$JGROUPS_CLUSTER_PASSWORD\"/>\n\
                    </digest-token>\n\
                </auth-protocol>\n"
  fi

  local ping_protocol=${JGROUPS_PING_PROTOCOL:-kubernetes.KUBE_PING}
  local socket_binding=$(get_socket_binding_for_ping "${ping_protocol}")
  local ping_protocol_element="<protocol type=\"${ping_protocol}\" ${socket_binding}/>"
  validate_ping_protocol "${ping_protocol}" 

  sed -i "s|<!-- ##JGROUPS_AUTH## -->|${JGROUPS_AUTH}|g" $CONFIG_FILE
  log_info "Configuring JGroups discovery protocol to ${ping_protocol}"
  sed -i "s|<!-- ##JGROUPS_PING_PROTOCOL## -->|${ping_protocol_element}|g" $CONFIG_FILE

  # OPENSHIFT_KUBE_PING_NAMESPACE / OPENSHIFT_KUBE_PING_LABELS are deprecated, so if we're using those and kubernetes.KUBE_PING, convert to new values
  if [ "${ping_protocol}" = "kubernetes.KUBE_PING" ]; then

    if [ -n "${OPENSHIFT_KUBE_PING_NAMESPACE}" ]; then
        if [ -z "${KUBERNETES_NAMESPACE}" ]; thenq
                export KUBERNETES_NAMESPACE="${OPENSHIFT_KUBE_PING_NAMESPACE}"
        fi
        log_warning "OPENSHIFT_KUBE_PING_NAMESPACE (${OPENSHIFT_KUBE_PING_NAMESPACE}) is deprecated and KUBERNETES_NAMESPACE is used when using kubernetes.KUBE_PING."
        unset OPENSHIFT_KUBE_PING_NAMESPACE
    fi

    if [ -n "${OPENSHIFT_KUBE_PING_LABELS}" ]; then
        if [ -z "${KUBERNETES_LABELS}" ]; then
            export KUBERNETES_LABELS="${OPENSHIFT_KUBE_PING_LABELS}"
        fi
        log_warning "OPENSHIFT_KUBE_PING_LABELS (${OPENSHIFT_KUBE_PING_LABELS}) is deprecated and KUBERNETES_LABELS is used when using kubernetes.KUBE_PING."
        unset OPENSHIFT_KUBE_PING_LABELS
    fi

 fi

}

