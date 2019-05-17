
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

preConfigure() {
  CONF_AUTH_MODE=$(getConfigurationMode "<!-- ##JGROUPS_AUTH## -->")
  CONF_PING_MODE=$(getConfigurationMode "<!-- ##JGROUPS_PING_PROTOCOL## -->")
}

postConfigure() {
  unset CONF_AUTH_MODE
  unset CONF_PING_MODE
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
            pods_labels="labelSelector=${labels}"
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
  elif [ "${protocol}" = "openshift.DNS_PING" ] || [ "${protocol}" = "dns.DNS_PING" ]; then
    validate_dns_ping_settings
  else
    log_warning "Unknown protocol specified for JGroups discovery protocol: $1. Expecting one of: openshift.DNS_PING, openshift.KUBE_PING, kubernetes.KUBE_PING or dns.DNS_PING."
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
    elif [ "${CONF_PING_MODE}" = "xml" ]; then
        echo "socket-binding=\"jgroups-mping\""
    elif [ "${CONF_PING_MODE}" = "cli" ]; then
      echo "jgroups-mping"
    fi
}

generate_jgroups_auth_config() {

  local cluster_password="${1}"
  local digest_algorithm="${2}"
  local config

  if [ -z "${cluster_password}" ]; then
      log_warning "No password defined for JGroups cluster. AUTH protocol will be disabled. Please define JGROUPS_CLUSTER_PASSWORD."
      config="<!--WARNING: No password defined for JGroups cluster. AUTH protocol has been disabled. Please define JGROUPS_CLUSTER_PASSWORD. -->"
  elif [ "${CONF_AUTH_MODE}" = "xml" ]; then
      config="\n <auth-protocol type=\"AUTH\">\n\
                    <digest-token algorithm=\"${digest_algorithm:-SHA-512}\">\n\
                        <shared-secret-reference clear-text=\"${cluster_password}\"/>\n\
                    </digest-token>\n\
                </auth-protocol>\n"
  elif [ "${CONF_AUTH_MODE}" = "cli" ]; then
    #TODO: :add-protocol is a deprecated operation, should be replace by a non-deprecated version
    config=$(cat <<EOF
        batch
         /subsystem=jgroups/stack=tcp:add-protocol(type=AUTH)
         /subsystem=jgroups/stack=tcp/protocol=AUTH/token=digest:add(algorithm="${digest_algorithm:-SHA-512}", shared-secret-reference={clear-text="${cluster_password}"})
        run-batch
EOF
   )
  fi
  echo "${config}"
}

generate_generic_ping_config() {
    local ping_protocol="${1}"
    local socket_binding="${2}"

    if [ "${ping_protocol}" = "openshift.DNS_PING" ]; then
        ping_protocol="dns.DNS_PING" # openshift.DNS_PING is deprecated and removed, but we alias it.
        log_warning "Ping protocol openshift.DNS_PING is deprecated, replacing with dns.DNS_PING instead."
    fi

    if [ "${ping_protocol}" = "openshift.KUBE_PING" ]; then
        ping_protocol="kubernetes.KUBE_PING" # openshift.KUBE_PING is deprecated and removed, but aliased
        log_warning "Ping protocol openshift.KUBE_PING is deprecated, replacing with kubernetes.KUBE_PING instead."
    fi

    # for DNS_PING, the record is my-port-name._my-port-protocol.my-svc.my-namespace
    if [ "${CONF_AUTH_MODE}" = "xml" ]; then
      config="<protocol type=\"${ping_protocol}\" ${socket_binding}/>"
    elif [ "${CONF_AUTH_MODE}" = "cli" ]; then
      local op="/subsystem=jgroups/stack=tcp:add-protocol(type=${ping_protocol})"
      if [ "${socket_binding}x" == "x" ]; then
        op="/subsystem=jgroups/stack=tcp:add-protocol(type=${ping_protocol}, socket-binding=${socket_binding})"
      fi
    read -d '' config << EOF
        batch
          ${op}
        run-batch
EOF
    fi

    echo "${config}"
}

generate_dns_ping_config() {

    local ping_protocol="${1}"
    local ping_service_name="${2}"
    local ping_service_port="${3}"
    local ping_service_namespace="${4}"
    local socket_binding="${5}"
    local ping_service_protocol="tcp"
    local config

    if [ "${ping_protocol}" = "openshift.DNS_PING" ]; then
        ping_protocol="dns.DNS_PING" # openshift.DNS_PING is deprecated and removed, but we alias it.
        log_warning "Ping protocol openshift.DNS_PING is deprecated, replacing with dns.DNS_PING instead."
    fi

    if [ "${ping_protocol}" = "openshift.KUBE_PING" ]; then
        ping_protocol="kubernetes.KUBE_PING" # openshift.KUBE_PING is deprecated and removed, but aliased
        log_warning "Ping protocol openshift.KUBE_PING is deprecated, replacing with kubernetes.KUBE_PING instead."
    fi

    # for DNS_PING, the record is ping-service-name, suffixes are determined from /etc/resolv.conf search domains.
    if [ "${CONF_PING_MODE}" = "xml" ]; then
      config="<protocol type=\"${ping_protocol}\" ${socket_binding}>"
      if [ "${ping_protocol}" = "dns.DNS_PING" ]; then
          config="${config}<property name=\"dns_query\">${ping_service_name}</property>"
          config="${config}<property name=\"async_discovery_use_separate_thread_per_request\">true</property>"
      fi
      config="${config}</protocol>"
    elif [ "${CONF_PING_MODE}" = "cli" ]; then
      #CLI operation is expected to fail if there is already a protocol configured with the same name
      #TODO: :add-protocol is a deprecated operation, should be replace by a non-deprecated version

      local op="/subsystem=jgroups/stack=tcp:add-protocol(type=${ping_protocol})"
      if [ "${socket_binding}x" == "x" ]; then
        op="/subsystem=jgroups/stack=tcp:add-protocol(type=${ping_protocol}, socket-binding=${socket_binding})"
      fi

      local op_prop1=""
      local op_prop2=""
      if [ "${ping_protocol}" = "dns.DNS_PING" ]; then
        op_prop1="/subsystem=jgroups/stack=tcp/protocol=${ping_protocol}/property=dns_query:add(value=${ping_service_name})"
        op_prop2="/subsystem=jgroups/stack=tcp/protocol=${ping_protocol}/property=async_discovery_use_separate_thread_per_request:add(value=true)"
      fi

      read -d '' config << EOF
        batch
          ${op}
          ${op_prop1}
          ${op_prop2}
        run-batch
EOF
    fi

    echo "${config}"
}

configure_ha() {
  # Set HA args
  IP_ADDR=`hostname -i`
  JBOSS_HA_ARGS="-b ${JBOSS_HA_IP:-${IP_ADDR}} -bprivate ${JBOSS_HA_IP:-${IP_ADDR}}"

  init_node_name

  JBOSS_HA_ARGS="${JBOSS_HA_ARGS} -Djboss.node.name=${JBOSS_NODE_NAME}"

  JGROUPS_AUTH=$(generate_jgroups_auth_config "${JGROUPS_CLUSTER_PASSWORD}" "${JGROUPS_DIGEST_TOKEN_ALGORITHM}")

  local ping_protocol=${JGROUPS_PING_PROTOCOL:-kubernetes.KUBE_PING}
  local socket_binding=$(get_socket_binding_for_ping "${ping_protocol}")
  validate_ping_protocol "${ping_protocol}"
  local ping_protocol_element

  if [ "${ping_protocol}" = "openshift.DNS_PING" ]; then
    ping_protocol="dns.DNS_PING" # openshift.DNS_PING is deprecated and removed, but we alias it.
    log_warning "Ping protocol openshift.DNS_PING is deprecated, replacing with dns.DNS_PING instead."
  fi

  if [ "${ping_protocol}" = "openshift.KUBE_PING" ]; then
    ping_protocol="kubernetes.KUBE_PING" # openshift.KUBE_PING is deprecated and removed, but aliased
    log_warning "Ping protocol openshift.KUBE_PING is deprecated, replacing with kubernetes.KUBE_PING instead."
  fi

  if [ "${ping_protocol}" = "dns.DNS_PING" ]; then
    ping_protocol_element=$(generate_dns_ping_config "${ping_protocol}" "${OPENSHIFT_DNS_PING_SERVICE_NAME}" "${OPENSHIFT_DNS_PING_SERVICE_PORT}" "${OPENSHIFT_DNS_PING_SERVICE_NAMESPACE}" "${socket_binding}")
  else
    ping_protocol_element=$(generate_generic_ping_config "${ping_protocol}" "${socket_binding}")
  fi

  if [ "${CONF_AUTH_MODE}" = "xml" ]; then
    sed -i "s|<!-- ##JGROUPS_AUTH## -->|${JGROUPS_AUTH}|g" $CONFIG_FILE
  elif [ "${CONF_AUTH_MODE}" = "cli" ]; then
    echo ${JGROUPS_AUTH} >> $CONFIG_FILE;
  fi

  log_info "Configuring JGroups discovery protocol to ${ping_protocol}"

  if [ "${CONF_PING_MODE}" = "xml" ]; then
    sed -i "s|<!-- ##JGROUPS_PING_PROTOCOL## -->|${ping_protocol_element}|g" $CONFIG_FILE
  elif [ "${CONF_PING_MODE}" = "cli" ]; then
    echo ${ping_protocol_element} >> $CONFIG_FILE;
  fi
}

