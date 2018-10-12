#!/bin/sh
# Openshift EAP CD launch script routines for configuring messaging

if [ -z "${TEST_ACTIVEMQ_SUBSYSTEM_FILE_INCLUDE}" ]; then
    ACTIVEMQ_SUBSYSTEM_FILE=$JBOSS_HOME/bin/launch/activemq-subsystem.xml
else
    ACTIVEMQ_SUBSYSTEM_FILE=${TEST_ACTIVEMQ_SUBSYSTEM_FILE_INCLUDE}
fi

if [ -z "${TEST_ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE}" ]; then
    ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE=$JBOSS_HOME/bin/launch/activemq-subsystem-no-embedded.xml
else
    ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE=${TEST_ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE}
fi

if [ -n "${TEST_LAUNCH_COMMON_INCLUDE}" ]; then
    source "${TEST_LAUNCH_COMMON_INCLUDE}"
else
    source $JBOSS_HOME/bin/launch/launch-common.sh
fi

if [ -n "${TEST_LOGGING_INCLUDE}" ]; then
    source "${TEST_LOGGING_INCLUDE}"
else
    source $JBOSS_HOME/bin/launch/logging.sh
fi

# Messaging doesn't currently support configuration using env files, but this is
# a start at what it would need to do to clear the env.  The reason for this is
# that the HornetQ subsystem is automatically configured if no service mappings
# are specified.  This could result in the configuration of both queuing systems.
prepareEnv() {
  # HornetQ configuration
  unset HORNETQ_QUEUES
  unset MQ_QUEUES
  unset HORNETQ_TOPICS
  unset MQ_TOPICS
  unset HORNETQ_CLUSTER_PASSWORD
  unset MQ_CLUSTER_PASSWORD
  unset DEFAULT_JMS_CONNECTION_FACTORY
  unset JBOSS_MESSAGING_HOST

  # A-MQ configuration
  IFS=',' read -a brokers <<< $MQ_SERVICE_PREFIX_MAPPING
  for broker in ${brokers[@]}; do
    service_name=${broker%=*}
    service=${service_name^^}
    service=${service//-/_}
    type=${service##*_}
    prefix=${broker#*=}

    unset ${prefix}_PROTOCOL
    protocol_env=${protocol//[-+.]/_}
    protocol_env=${protocol_env^^}
    unset ${service}_${protocol_env}_SERVICE_HOST
    unset ${service}_${protocol_env}_SERVICE_PORT
    
    unset ${prefix}_JNDI
    unset ${prefix}_USERNAME
    unset ${prefix}_PASSWORD

    for queue in ${queues[@]}; do
      queue_env=${prefix}_QUEUE_${queue^^}
      queue_env=${queue_env//[-\.]/_}
      unset ${queue_env}_PHYSICAL
      unset ${queue_env}_JNDI
    done
    unset ${prefix}_QUEUES

    for topic in ${topics[@]}; do
      topic_env=${prefix}_TOPIC_${topic^^}
      topic_env=${topic_env//[-\.]/_}
      unset ${topic_env}_PHYSICAL
      unset ${topic_env}_JNDI
    done
    unset ${prefix}_TOPICS
  done
  
  unset MQ_SERVICE_PREFIX_MAPPING
  unset MQ_SIMPLE_DEFAULT_PHYSICAL_DESTINATION
}

configure() {
  configure_artemis_address
  inject_brokers
  configure_mq
  configure_thread_pool
  disable_unused_rar
}

configure_artemis_address() {
    IP_ADDR=${JBOSS_MESSAGING_HOST:-`hostname -i`}
    JBOSS_MESSAGING_ARGS="${JBOSS_MESSAGING_ARGS} -Djboss.messaging.host=${IP_ADDR}"
    echo "${JBOSS_MESSAGING_ARGS}"
}

configure_mq_destinations() {
  IFS=',' read -a queues <<< ${MQ_QUEUES:-$HORNETQ_QUEUES}
  IFS=',' read -a topics <<< ${MQ_TOPICS:-$HORNETQ_TOPICS}

  destinations=""
  if [ "${#queues[@]}" -ne "0" -o "${#topics[@]}" -ne "0" ]; then
    if [ "${#queues[@]}" -ne "0" ]; then
      for queue in ${queues[@]}; do
        destinations="${destinations}<jms-queue name=\"${queue}\" entries=\"/queue/${queue}\"/>\n"
      done
    fi
    if [ "${#topics[@]}" -ne "0" ]; then
      for topic in ${topics[@]}; do
        destinations="${destinations}<jms-topic name=\"${topic}\" entries=\"/topic/${topic}\"/>\n"
      done
    fi
  fi
  echo "${destinations}" | sed ':a;N;$!ba;s|\n|\\n|g'
}

configure_mq_cluster_password() {
  if [ -n "${MQ_CLUSTER_PASSWORD:-HORNETQ_CLUSTER_PASSWORD}" ] ; then
    echo "${JBOSS_MESSAGING_ARGS} -Djboss.messaging.cluster.password=${MQ_CLUSTER_PASSWORD:-HORNETQ_CLUSTER_PASSWORD}" | sed ':a;N;$!ba;s|\n|\\n|g'
  fi
}

configure_mq() {
  if [ "$REMOTE_AMQ_BROKER" != "true" ] ; then
    JBOSS_MESSAGING_ARGS=$(configure_mq_cluster_password)
    destinations=$(configure_mq_destinations)
    # We need the broker if they configured destinations or didn't explicitly disable the broker AND there's a point to doing it because the marker exists
    if ([ -n "${destinations}" ] || [ "x${DISABLE_EMBEDDED_JMS_BROKER}" != "xtrue" ]) && grep -q '<!-- ##MESSAGING_SUBSYSTEM_CONFIG## -->' ${CONFIG_FILE}; then

      log_warning "Configuration of an embedded messaging broker within the appserver is enabled but is not recommended. Support for such a configuration will be removed in a future release."
      if [ "x${DISABLE_EMBEDDED_JMS_BROKER}" != "xtrue" ]; then
        log_info "If you are not configuring messaging destinations, to disable configuring an embedded messaging broker set the DISABLE_EMBEDDED_JMS_BROKER environment variable to true."
      fi

      activemq_subsystem=$(sed -e "s|<!-- ##DESTINATIONS## -->|${destinations}|" <"${ACTIVEMQ_SUBSYSTEM_FILE}" | sed ':a;N;$!ba;s|\n|\\n|g')
      sed -i "s|<!-- ##MESSAGING_SUBSYSTEM_CONFIG## -->|${activemq_subsystem%$'\n'}|" "${CONFIG_FILE}"
    fi
    #Handle the messaging socket-binding separately just in case its marker is present but the subsystem one is not
    if ([ -n "${destinations}" ] || [ "x${DISABLE_EMBEDDED_JMS_BROKER}" != "xtrue" ]) && grep -q '<!-- ##MESSAGING_PORTS## -->' ${CONFIG_FILE}; then
      # We don't warn about this as socket-bindings are pretty harmless
      sed -i 's|<!-- ##MESSAGING_PORTS## -->|<socket-binding name="messaging" port="5445"/><socket-binding name="messaging-throughput" port="5455"/>|' "${CONFIG_FILE}"
    fi
  fi
}

# Currently, the JVM is not cgroup aware and cannot be trusted to generate default values for
# threads pool args. Therefore, if there are resource limits specifed by the container, this function
# will configure the thread pool args using cgroups and the formulae provied by https://github.com/apache/activemq-artemis/blob/master/artemis-core-client/src/main/java/org/apache/activemq/artemis/api/core/client/ActiveMQClient.java
configure_thread_pool() {
  if [ -a "${CONTAINER_LIMITS_INCLUDE}" ]; then
    source ${CONTAINER_LIMITS_INCLUDE}
  else
    source /opt/run-java/container-limits
  fi
  if [ -n "$CORE_LIMIT" ]; then
    local mtp=$(expr 8 \* $CORE_LIMIT) # max thread pool size
    local ctp=5                                  # core thread pool size
    JBOSS_MESSAGING_ARGS="${JBOSS_MESSAGING_ARGS}
    -Dactivemq.artemis.client.global.thread.pool.max.size=$mtp
    -Dactivemq.artemis.client.global.scheduled.thread.pool.core.size=$ctp"
    echo "${JBOSS_MESSAGING_ARGS}"
  fi
}

# <!-- ##AMQ_REMOTE_CONTEXT## -->
# deprecated, not used by the new external connector
generate_remote_artemis_naming() {
    declare remote_context_name="${1}"
    declare remote_host="${2}"
    declare remote_port="${3}"
    echo "<bindings><external-context name=\"java:global/${remote_context_name}\" module=\"org.apache.activemq.artemis\" class=\"javax.naming.InitialContext\">
              <environment>
                  <property name=\"java.naming.factory.initial\" value=\"org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory\"/>
                      <property name=\"java.naming.provider.url\" value=\"tcp://${remote_host}:${remote_port}\"/>
                      <!-- ##AMQ7_CONFIG_PROPERTIES## -->
              </environment>
          </external-context>
          <!-- ##AMQ_LOOKUP_OBJECTS## --></bindings>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# $1 - name - messaging-remote-throughput
# <!-- ##AMQ_REMOTE_CONNECTOR## -->
generate_remote_artemis_remote_connector() {
    declare name="${1}"
    declare socket_binding_name="${2}"
    echo "<remote-connector name=\"${name}\" socket-binding=\"${socket_binding_name}\"/>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# <!-- ##AMQ_POOLED_CONNECTION_FACTORY## -->
generate_remote_artemis_connection_factory() {
    declare name="${1}"
    declare username="${2}"
    declare password="${3}"
    declare connectors="${4}"
    declare entries="${5}"
    echo "<pooled-connection-factory name=\"${name}\" user=\"${username}\" password=\"${password}\" entries=\"${entries}\" connectors=\"${connectors}\" transaction=\"xa\"/>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# <!-- ##AMQ7_CONFIG_PROPERTIES## -->
generate_remote_artemis_property() {
    declare object_type="${1}"
    declare object_name="${2}"
    echo "<property name=\"${object_type}.${object_name}\" value=\"${object_name}\"/>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# <!-- ##AMQ_LOOKUP_OBJECTS## -->
generate_remote_artemis_lookup() {
    declare remote_context="${1}"
    declare object_name="${2}"
    echo "<lookup name=\"java:/${object_name}\" lookup=\"java:global/${remote_context}/${object_name}\"/>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# <!-- ##AMQ_MESSAGING_SOCKET_BINDING## -->
generate_remote_artemis_socket_binding() {
    declare name="${1}"
    declare remote_host="${2}"
    declare remote_port="${3}"
    echo "<outbound-socket-binding name=\"${name}\">
            <remote-destination host=\"${remote_host}\" port=\"${port}\"/>
         </outbound-socket-binding>" | sed -e ':a;N;$!ba;s|\n|\\n|g'
}

# <!-- ##AMQ_EXTERNAL_JMS_CONFIG## -->
generate_external_jms_lookup() {
    declare type="${1,,}" # queue / topic
    declare connector_name="${2}"
    declare name="${3}" # MyQueue / MyTopic

    local result=""

    if [ -z "${name}" ]; then
        result="<!-- Error: name is required for external JMS object -->"
        echo ${result}
        return
    fi

    # /HELLOWORLDMDBQueue  java:/queue/HELLOWORLDMDBQueue
    if [ "${type}" = "queue" ]; then
        result="<external-jms-queue name=\"${name}\" entries=\"java:/jms/${connector_name}/${name} ${name}\"/>"
    elif [ "${type}" = "topic" ]; then
        result="<external-jms-topic name=\"${name}\" entries=\"java:/jms/${connector_name}/${name} ${name}\"/>"
    else
        result="<!-- Error: Unknown type (${type}) for external JMS configuration. valid values are: {queue, topic} -->"
    fi
    echo "${result}"
}

generate_object_config() {
  declare name="${1}"
  declare jndi_name="${2}"
  declare class="${3}"

  ao="
                        <admin-object
                              class-name=\"${class}\"
                              jndi-name=\"${jndi_name}\"
                              use-java-context=\"true\"
                              pool-name=\"${name}\">
                            <config-property name=\"PhysicalName\">${name}</config-property>
                        </admin-object>"
  echo $ao
}

generate_resource_adapter() {
  declare service_name="${1}"
  declare connection_factory_jndi="${2}"
  declare broker_username="${3}"
  declare broker_password="${4}"
  declare protocol="${5}"
  declare broker_host="${6}"
  declare broker_port="${7}"
  declare prefix="${8}"
  declare archive="${9}"
  declare driver="${10}"
  declare queue_names="${11}"
  declare topic_names="${12}"
  declare ra_tracking="${13}"
  declare resource_counter="${14}"

  log_info "Generating resource adapter configuration for service: $1 (${10})" >&2
  IFS=',' read -a queues <<< ${queue_names}
  IFS=',' read -a topics <<< ${topic_names}

  local ra_id=""
  # this preserves the expected behavior of the first RA, and doesn't append a number. Any additional RAs will have -count appended.
  if [ "${resource_counter}" -eq "0" ]; then
    ra_id="${archive}"
  else
    ra_id="${archive}-${resource_counter}"
  fi

  # if we don't declare a EJB_RESOURCE_ADAPTER_NAME, then just use the first one
  if [ -z "${EJB_RESOURCE_ADAPTER_NAME}" ]; then
    export EJB_RESOURCE_ADAPTER_NAME="${ra_id}"
  fi

  case "${driver}" in
    "amq")
      ra="
                <resource-adapter id=\"${ra_id}\">
                    <archive>${archive}</archive>
                    <transaction-support>XATransaction</transaction-support>
                    <config-property name=\"UserName\">${broker_username}</config-property>
                    <config-property name=\"Password\">${broker_password}</config-property>
                    <config-property name=\"ServerUrl\">tcp://${broker_host}:${broker_port}?jms.rmIdFromConnectionId=true</config-property>
                    <connection-definitions>
                        <connection-definition
                              "${ra_tracking}"
                              class-name=\"org.apache.activemq.ra.ActiveMQManagedConnectionFactory\"
                              jndi-name=\"${connection_factory_jndi}\"
                              enabled=\"true\"
                              pool-name=\"${service_name}-ConnectionFactory\">
                            <xa-pool>
                                <min-pool-size>1</min-pool-size>
                                <max-pool-size>20</max-pool-size>
                                <prefill>false</prefill>
                                <is-same-rm-override>false</is-same-rm-override>
                            </xa-pool>
                            <recovery>
                                <recover-credential>
                                    <user-name>${broker_username}</user-name>
                                    <password>${broker_password}</password>
                                </recover-credential>
                            </recovery>
                        </connection-definition>
                    </connection-definitions>
                    <admin-objects>"

      # backwards-compatability flag per CLOUD-329
      simple_def_phys_dest=$(echo "${MQ_SIMPLE_DEFAULT_PHYSICAL_DESTINATION}" | tr [:upper:] [:lower:])

      if [ "${#queues[@]}" -ne "0" ]; then
        for queue in ${queues[@]}; do
          queue_env=${prefix}_QUEUE_${queue^^}
          queue_env=${queue_env//[-\.]/_}

          if [ "${simple_def_phys_dest}" = "true" ]; then
            physical=$(find_env "${queue_env}_PHYSICAL" "$queue")
          else
            physical=$(find_env "${queue_env}_PHYSICAL" "queue/$queue")
          fi
          jndi=$(find_env "${queue_env}_JNDI" "java:/queue/$queue")
          class="org.apache.activemq.command.ActiveMQQueue"
          log_info "generating object config for ${physical}"
          ra="$ra$(generate_object_config $physical $jndi $class)"
        done
      fi

      if [ "${#topics[@]}" -ne "0" ]; then
        for topic in ${topics[@]}; do
          topic_env=${prefix}_TOPIC_${topic^^}
          topic_env=${topic_env//[-\.]/_}

          if [ "${simple_def_phys_dest}" = "true" ]; then
            physical=$(find_env "${topic_env}_PHYSICAL" "$topic")
          else
            physical=$(find_env "${topic_env}_PHYSICAL" "topic/$topic")
          fi
          jndi=$(find_env "${topic_env}_JNDI" "java:/topic/$topic")
          class="org.apache.activemq.command.ActiveMQTopic"
          log_info "generating object config for ${physical}"
          ra="$ra$(generate_object_config $physical $jndi $class)"
        done
      fi

      ra="$ra
                    </admin-objects>
                </resource-adapter>"
    ;;
  esac

  echo ${ra} | sed ':a;N;$!ba;s|\n|\\n|g'
}

# Finds the name of the broker services and generates resource adapters
# based on this info
inject_brokers() {
  # Find all brokers in the $MQ_SERVICE_PREFIX_MAPPING separated by ","
  IFS=',' read -a brokers <<< $MQ_SERVICE_PREFIX_MAPPING

  local subsystem_added=false
  REMOTE_AMQ_BROKER=false
  REMOTE_AMQ6=false
  REMOTE_AMQ7=false
  has_default_cnx_factory=false

  defaultJmsConnectionFactoryJndi="$DEFAULT_JMS_CONNECTION_FACTORY"

  if [ "${#brokers[@]}" -eq "0" ] ; then
    if [ -z "$defaultJmsConnectionFactoryJndi" ]; then
        defaultJmsConnectionFactoryJndi="java:jboss/DefaultJMSConnectionFactory"
    fi
  else
    local counter=0
    # names / types are determined from the name, for example:
    # "eap-app-amq=MQ" the -amq indicates this is AMQ6
    # example config:
    # MQ_SERVICE_PREFIX_MAPPING="eap-app-amq=MQ"
    # MQ_JNDI=java:/ConnectionFactory
    # MQ_USERNAME=admin
    # MQ_PASSWORD=admin
    # MQ_PROTOCOL=tcp
    # MQ_QUEUES=HELLOWORLDMDBQueue
    # MQ_TOPICS=HELLOWORLDMDBTopic
    #
    # MQ_SERVICE_PREFIX_MAPPING is a of brokers, seperated by comma, all using the same format.
    #
    for broker in ${brokers[@]}; do
      log_info "Processing broker($counter): $broker"
      # Example: Service Name: eap-app-amq, Service: EAP_APP_AMQ, Type: AMQ, Prefix: MQ
      service_name=${broker%=*}
      service=${service_name^^}
      service=${service//-/_}
      type=${service##*_}
      # generally MQ
      prefix=${broker#*=}

      # XXX: only tcp (openwire) is supported by EAP
      # Protocol environment variable name format: [NAME]_[BROKER_TYPE]_PROTOCOL
      protocol=$(find_env "${prefix}_PROTOCOL" "tcp")
      
      if [ "${protocol}" == "openwire" ]; then
        protocol="tcp"
      fi

      if [ "${protocol}" != "tcp" ]; then
        log_warning "There is a problem with your service configuration!"
        log_warning "Only openwire (tcp) transports are supported."
        continue
      fi

      protocol_env=${protocol//[-+.]/_}
      protocol_env=${protocol_env^^}

      # remap for AMQ7 config vars, AMQ7 gets looked up as AMQ
      if [ "$type" = "AMQ7" ] ; then
        host=$(find_env "${service/%AMQ7/AMQ}_${protocol_env}_SERVICE_HOST")
        port=$(find_env "${service/%AMQ7/AMQ}_${protocol_env}_SERVICE_PORT")
      else
        host=$(find_env "${service}_${protocol_env}_SERVICE_HOST")
        port=$(find_env "${service}_${protocol_env}_SERVICE_PORT")
      fi

      if [ -z $host ] || [ -z $port ]; then
        log_warning "There is a problem with your service configuration!"
        log_warning "You provided following MQ mapping (via MQ_SERVICE_PREFIX_MAPPING environment variable): $brokers. To configure resource adapters we expect ${service}_${protocol_env}_SERVICE_HOST and ${service}_${protocol_env}_SERVICE_PORT to be set."
        log_warning
        log_warning "Current values:"
        log_warning
        log_warning "${service}_${protocol_env}_SERVICE_HOST: $host"
        log_warning "${service}_${protocol_env}_SERVICE_PORT: $port"
        log_warning
        log_warning "Please make sure you provided correct service name and prefix in the mapping. Additionally please check that you do not set portalIP to None in the $service_name service. Headless services are not supported at this time."
        log_warning
        log_warning "The ${type,,} broker for $prefix service WILL NOT be configured."
        continue
      fi

      # Custom JNDI environment variable name format: [NAME]_[BROKER_TYPE]_JNDI
      jndi=$(find_env "${prefix}_JNDI" "java:/$service_name/ConnectionFactory")

      # username environment variable name format: [NAME]_[BROKER_TYPE]_USERNAME
      username=$(find_env "${prefix}_USERNAME")

      # password environment variable name format: [NAME]_[BROKER_TYPE]_PASSWORD
      password=$(find_env "${prefix}_PASSWORD")

      # queues environment variable name format: [NAME]_[BROKER_TYPE]_QUEUES
      queues=$(find_env "${prefix}_QUEUES")

      # topics environment variable name format: [NAME]_[BROKER_TYPE]_TOPICS
      topics=$(find_env "${prefix}_TOPICS")

      tracking=$(find_env "${prefix}_TRACKING")
      if [ -n "${tracking}" ]; then
         ra_tracking="tracking=\"${tracking}\""
      fi

      case "$type" in
        "AMQ")
          driver="amq"
          archive="activemq-rar.rar"
          ra=$(generate_resource_adapter ${service_name} ${jndi} ${username} ${password} ${protocol} ${host} ${port} ${prefix} ${archive} ${driver} "${queues}" "${topics}" "${ra_tracking}" ${counter})
          sed -i "s|<!-- ##RESOURCE_ADAPTERS## -->|${ra%$'\n'}<!-- ##RESOURCE_ADAPTERS## -->|" $CONFIG_FILE
          REMOTE_AMQ_BROKER=true
          REMOTE_AMQ6=true
          ;;
        "AMQ7")
         driver="amq7"
         archive=""
         default_connector_name="remote-amq"
         default_cnx_factory_name="activemq-ra-remote"
         default_socket_binding_name="messaging-remote-throughput"
         # XXX not used by remote
         default_entries="java:/JmsXA java:/RemoteJmsXA java:jboss/RemoteJmsXA"
         EJB_RESOURCE_ADAPTER_NAME="${default_cnx_factory_name}.rar"
         REMOTE_AMQ_BROKER=true
         REMOTE_AMQ7=true
         if [ "$subsystem_added" != "true" ] ; then
             activemq_subsystem=$(sed -e ':a;N;$!ba;s|\n|\\n|g' <"${ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE}")
             # only added once.
             sed -i "s|<!-- ##MESSAGING_SUBSYSTEM_CONFIG## -->|${activemq_subsystem%$'\n'}|" $CONFIG_FILE
             subsystem_added=true
             # make sure the default connection factory isn't set on another cnx factory
             sed -i "s|java:jboss/DefaultJMSConnectionFactory||g" $CONFIG_FILE
             # this will be on the remote ConnectionFactory, so rename the local one until the embedded broker is dropped.
             sed -i "s|java:/JmsXA|java:/JmsXALocal|" $CONFIG_FILE
         fi

         connector_name="${default_connector_name}"
         socket_binding_name="${default_socket_binding_name}"
         cnx_factory_name="${default_cnx_factory_name}"
         entries="${default_entries} ${jndi}"
         if [ "${counter}" -ne "0" ]; then
            connector_name="${default_connector_name}-${counter}"
            socket_binding_name="${default_socket_binding_name}-${counter}"
            cnx_factory_name="${default_cnx_factory_name}-${counter}"
            # this one doesn't get the default entries
            entries="${jndi}"
         fi

         connector=$(generate_remote_artemis_remote_connector ${connector_name} ${socket_binding_name})
         sed -i "s|<!-- ##AMQ_REMOTE_CONNECTOR## -->|${connector%$'\n'}<!-- ##AMQ_REMOTE_CONNECTOR## -->|" $CONFIG_FILE

         entries="java:/jms/${connector_name}/JmsConnectionFactory"
         # if no default is defined the first one is the default
         if [ -z "$defaultJmsConnectionFactoryJndi" ] ; then
            defaultJmsConnectionFactoryJndi="${entries}"
         fi

         cnx_factory=$(generate_remote_artemis_connection_factory ${cnx_factory_name} ${username} ${password} ${connector_name} "${entries}")
         sed -i "s|<!-- ##AMQ_POOLED_CONNECTION_FACTORY## -->|${cnx_factory%$'\n'}<!-- ##AMQ_POOLED_CONNECTION_FACTORY## -->|" $CONFIG_FILE

         socket_binding=$(generate_remote_artemis_socket_binding ${socket_binding_name} ${host} ${port})
         sed -i "s|<!-- ##AMQ_MESSAGING_SOCKET_BINDING## -->|${socket_binding%$'\n'}<!-- ##AMQ_MESSAGING_SOCKET_BINDING## -->|" $CONFIG_FILE

         IFS=',' read -a amq7_queues <<< ${queues:-}
         if [ "${#amq7_queues[@]}" -ne "0" ]; then
            for q in ${amq7_queues[@]}; do
                lookup=$(generate_external_jms_lookup "queue" "${connector_name}" "${q}")
                sed -i "s|<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->|${lookup%$'\n'}<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->|" $CONFIG_FILE
            done
         fi

         IFS=',' read -a amq7_topics <<< ${topics:-}
         if [ "${#amq7_topics[@]}" -ne "0" ]; then
            for t in ${amq7_topics[@]}; do
                lookup=$(generate_external_jms_lookup "topic" "${connector_name}" "${t}")
                sed -i "s|<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->|${lookup%$'\n'}<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->|" $CONFIG_FILE
            done
         fi
         ;;
      esac

      # first defined broker is the default.
      if [ -z "$defaultJmsConnectionFactoryJndi" ] ; then
        defaultJmsConnectionFactoryJndi="${jndi}"
      fi

      # increment RA counter
      counter=$((counter+1))
    done
    if [ "$REMOTE_AMQ_BROKER" = "true" ] ; then
      JBOSS_MESSAGING_ARGS="${JBOSS_MESSAGING_ARGS} -Dejb.resource-adapter-name=${EJB_RESOURCE_ADAPTER_NAME:-activemq-rar.rar}"
    fi
  fi

  defaultJms=""
  if [ -n "$defaultJmsConnectionFactoryJndi" ]; then
    defaultJms="jms-connection-factory=\"$defaultJmsConnectionFactoryJndi\""
  fi

  # new format
  sed -i "s|jms-connection-factory=\"##DEFAULT_JMS##\"|${defaultJms}|" $CONFIG_FILE
  # legacy format, bare ##DEFAULT_JMS##
  sed -i "s|##DEFAULT_JMS##|${defaultJms}|" $CONFIG_FILE

}

disable_unused_rar() {
  # Put down a skipdeploy marker for the legacy activemq-rar.rar unless there is a .dodeploy marker
  # or the rar is mentioned in the config file
  local base_rar="$JBOSS_HOME/standalone/deployments/activemq-rar.rar"
  if [ -e "${base_rar}" ] && [ ! -e "${base_rar}.dodeploy" ] && ! grep -q -E "activemq-rar\.rar" $CONFIG_FILE; then
    touch "$JBOSS_HOME/standalone/deployments/activemq-rar.rar.skipdeploy"
  fi
}
