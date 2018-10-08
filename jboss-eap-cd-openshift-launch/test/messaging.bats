#!/bin/bash
# fake JBOSS_HOME
export JBOSS_HOME=$BATS_TEST_DIRNAME
export TEST_ACTIVEMQ_SUBSYSTEM_FILE_INCLUDE=$BATS_TEST_DIRNAME/../added/launch/activemq-subsystem.xml
export TEST_ACTIVEMQ_SUBSYSTEM_NO_EMBEDDED_FILE=$BATS_TEST_DIRNAME/../added/launch/activemq-subsystem-no-embedded.xml
# fake the logger so we don't have to deal with colors
export TEST_LOGGING_INCLUDE=$BATS_TEST_DIRNAME/../../test-common/logging.sh
export TEST_LAUNCH_COMMON_INCLUDE=$BATS_TEST_DIRNAME/../../test-common/launch-common.sh
export BATS_TEST_SKIPPED=

export INPUT_CONTENT="<test-content><!-- ##MESSAGING_SUBSYSTEM_CONFIG## --><!-- ##MESSAGING_PORTS## --></test-content>"
export SOCKET_BINDING_ONLY_INPUT_CONTENT="<test-content><!-- ##MESSAGING_PORTS## --></test-content>"
export SOCKET_BINDING_ONLY_OUTPUT_CONTENT='<test-content><socket-binding name="messaging" port="5445"/><socket-binding name="messaging-throughput" port="5455"/></test-content>'

load "$BATS_TEST_DIRNAME/../added/launch/messaging.sh"

setup() {
  export CONFIG_FILE="${BATS_TMPDIR}/standalone-openshift.xml"
}

#teardown() {
#    if [ -n "${CONFIG_FILE}" ] && [ -f "${CONFIG_FILE}" ]; then
#        rm "${CONFIG_FILE}"
#    fi
#}

@test "Configure MQ config file with markers" {
    expected=$(cat "$BATS_TEST_DIRNAME/standalone-openshift-configure-mq.xml" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    run configure_mq
    echo "Output: ${output}"
    result=$(cat "${CONFIG_FILE}" | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
    echo "${lines[0]}" | grep "WARN Configuration of an embedded messaging broker"
    [ $? -eq 0 ]
    echo "${lines[1]}" | grep "INFO If you are not configuring messaging destinations"
    [ $? -eq 0 ]
}

@test "Configure MQ config file without markers" {
    expected=$(echo "<test-content/>" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo '<test-content/>' > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Configure MQ config file with markers, destinations and disabled" {
    expected=$(cat $BATS_TEST_DIRNAME/standalone-openshift-configure-mq.xml | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    export DISABLE_EMBEDDED_JMS_BROKER="true"
    run configure_mq
    echo "Output: ${output}"
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
    echo "${lines[0]}" | grep "WARN Configuration of an embedded messaging broker"
    [ $? -eq 0 ]
    [ "${lines[1]}" = "" ]
}

@test "Configure MQ config file with socket-binding marker only" {
    expected=$(echo "${SOCKET_BINDING_ONLY_OUTPUT_CONTENT}" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${SOCKET_BINDING_ONLY_INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Configure MQ config file with socket-binding marker only and destinations" {
    expected=$(echo "${SOCKET_BINDING_ONLY_OUTPUT_CONTENT}" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${SOCKET_BINDING_ONLY_INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Configure MQ config file with socket-binding marker only, destinations and disabled" {
    expected=$(echo "${SOCKET_BINDING_ONLY_OUTPUT_CONTENT}"  | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${SOCKET_BINDING_ONLY_INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    export DISABLE_EMBEDDED_JMS_BROKER="true"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Configure MQ config file with socket-binding marker only embedded disabled" {
    expected=$(echo "${SOCKET_BINDING_ONLY_INPUT_CONTENT}" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${SOCKET_BINDING_ONLY_INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export DISABLE_EMBEDDED_JMS_BROKER="true"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Configure Artemis address" {
    expected=" -Djboss.messaging.host=1.2.3.4"
    export JBOSS_MESSAGING_HOST="1.2.3.4"
    run configure_artemis_address
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ destinations" {
    expected=$(cat <<EOF
<jms-queue name="queue1" entries="/queue/queue1"/>\n<jms-queue name="queue2" entries="/queue/queue2"/>\n<jms-topic name="topic1" entries="/topic/topic1"/>\n<jms-topic name="topic2" entries="/topic/topic2"/>\n
EOF
)
    export MQ_QUEUES="queue1,queue2"
    export MQ_TOPICS="topic1,topic2"
    run configure_mq_destinations
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ cluster password" {
    expected=" -Djboss.messaging.cluster.password=somepassword4mq"
    export MQ_CLUSTER_PASSWORD="somepassword4mq"
    run configure_mq_cluster_password
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ cluster password - JBOSS_MESSAGING_ARGS set" {
    export JBOSS_MESSAGING_ARGS="-DsomeotherArg=foo"
    expected="${JBOSS_MESSAGING_ARGS} -Djboss.messaging.cluster.password=somepassword4mq"
    export MQ_CLUSTER_PASSWORD="somepassword4mq"

    run configure_mq_cluster_password
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ cluster password - HornetQ" {
    expected=" -Djboss.messaging.cluster.password=somepassword4hornetQ"
    export MQ_CLUSTER_PASSWORD="somepassword4hornetQ"
    run configure_mq_cluster_password
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ cluster password - HornetQ - JBOSS_MESSAGING_ARGS set" {
    export JBOSS_MESSAGING_ARGS="-DsomeotherArgForHornetQ=foo"
    expected="${JBOSS_MESSAGING_ARGS} -Djboss.messaging.cluster.password=somepassword4hornetQ"
    export MQ_CLUSTER_PASSWORD="somepassword4hornetQ"
    run configure_mq_cluster_password
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure MQ config file with markers embedded disabled" {
    expected=$(echo "${INPUT_CONTENT}" | xmllint --format --noblanks -)
    echo "CONFIG_FILE: ${CONFIG_FILE}"
    echo "${INPUT_CONTENT}" > ${CONFIG_FILE}
    export MQ_CLUSTER_PASSWORD="somemqpassword"
    export DISABLE_EMBEDDED_JMS_BROKER="true"
    run configure_mq
    echo "Output: ${output}"
    [ "${output}" = "" ]
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result: ${result}"
}

@test "Configure Thread Pool" {
    export JBOSS_MESSAGING_ARGS=" -DsomeArg=foo"
    expected="${JBOSS_MESSAGING_ARGS}
    -Dactivemq.artemis.client.global.thread.pool.max.size=40
    -Dactivemq.artemis.client.global.scheduled.thread.pool.core.size=5"
    touch $BATS_TMPDIR/container_limits
    export CONTAINER_LIMITS_INCLUDE=$BATS_TMPDIR/container_limits
    export CORE_LIMIT=5
    run configure_thread_pool
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Configure Thread Pool - existing JBOSS_MESSAGING_ARGS" {
    export JBOSS_MESSAGING_ARGS="-DsomeMessagingArg=foo -DsomeOtherArg=bar"
    expected="${JBOSS_MESSAGING_ARGS}
    -Dactivemq.artemis.client.global.thread.pool.max.size=40
    -Dactivemq.artemis.client.global.scheduled.thread.pool.core.size=5"
    touch $BATS_TMPDIR/container_limits
    export CONTAINER_LIMITS_INCLUDE=$BATS_TMPDIR/container_limits
    export CORE_LIMIT=5
    run configure_thread_pool
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis naming" {
    expected=$(cat <<EOF
<bindings><external-context name="java:global/remoteContextName1" module="org.apache.activemq.artemis" class="javax.naming.InitialContext">\n              <environment>\n                  <property name="java.naming.factory.initial" value="org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory"/>\n                      <property name="java.naming.provider.url" value="tcp://remoteHost2:remotePort3"/>\n                      <!-- ##AMQ7_CONFIG_PROPERTIES## -->\n              </environment>\n          </external-context>\n          <!-- ##AMQ_LOOKUP_OBJECTS## --></bindings>
EOF
)
    run generate_remote_artemis_naming "remoteContextName1" "remoteHost2" "remotePort3"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis connector" {
    expected="<remote-connector name=\"connectorName\" socket-binding=\"socketBindingName\"/>"
    run generate_remote_artemis_remote_connector "connectorName" "socketBindingName"
    echo "Result: ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis connection factory" {
    expected=$(cat <<EOF
<pooled-connection-factory name="factoryName1" user="username2" password="password3" entries="entries5" connectors="connector4" transaction="xa"/>
EOF
)
    run generate_remote_artemis_connection_factory "factoryName1" "username2" "password3" "connector4" "entries5"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis property" {
    expected=$(cat <<EOF
<property name="queueType1.queueName2" value="queueName2"/>
EOF
)
    run generate_remote_artemis_property "queueType1" "queueName2"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis lookup" {
    expected=$(cat <<EOF
<lookup name="java:/objectName2" lookup="java:global/remoteContext1/objectName2"/>
EOF
)
    run generate_remote_artemis_lookup "remoteContext1" "objectName2"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate remote Artemis socket binding" {
    expected=$(cat <<EOF
<outbound-socket-binding name="name1">\n            <remote-destination host="host2" port=""/>\n         </outbound-socket-binding>
EOF
)
    run generate_remote_artemis_socket_binding "name1" "host2" "port3"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate MQ object config" {
    expected=$(cat <<EOF
<admin-object class-name="class3" jndi-name="jndiName2" use-java-context="true" pool-name="name1"> <config-property name="PhysicalName">name1</config-property> </admin-object>
EOF
)
    run generate_object_config "name1" "jndiName2" "class3"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

test_generate_resource_adapter() {
# don't validate log / stderr output
    generate_resource_adapter "$@" 2>/dev/null
}

@test "Generate Resource Adapter" {
    expected=$(xmllint --format --noblanks $BATS_TEST_DIRNAME/standalone-openshift-generate-ra.xml)
    ra_tracking="tracking=\"${tracking}\""
    run test_generate_resource_adapter "serviceName1" "connectionFactory2" "brokerUsername3" "brokerPassword4" "protocol5" \
    "brokerHost6" "brokerPort7" "prefix8" "archive9" "amq" "queueName11" "topicNames12" "${ra_tracking}" "0"
    result=$(echo ${output} | sed 's|\\n||g' | xmllint --format --noblanks -)
    echo "Result:   ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

test_inject_brokers() {
# don't validate log / stderr output
    generate_resource_adapter "$@" #2>/dev/null
}

@test "Inject brokers - AMQ 6" {
    expected=$(cat  $BATS_TEST_DIRNAME/standalone-openshift-configure-mq-amq6.xml | xmllint --format --noblanks -)
    # AMQ6: "eap-app-amq=MQ" the -amq indicates this is AMQ6
    # example config:
    # MQ_SERVICE_PREFIX_MAPPING="eap-app-amq=MQ"
    # EAP_APP_AMQ_TCP_SERVICE_HOST=localhost
    # EAP_APP_AMQ_TCP_SERVICE_PORT=61616
    # MQ_JNDI=java:/ConnectionFactory
    # MQ_USERNAME=adminUser
    # MQ_PASSWORD=adminPassword
    # MQ_PROTOCOL=tcp
    # MQ_QUEUES=HELLOWORLDMDBQueue
    # MQ_TOPICS=HELLOWORLDMDBTopic

    export MQ_SERVICE_PREFIX_MAPPING="eap-app-amq=MQ"
    export EAP_APP_AMQ_TCP_SERVICE_HOST=localhost
    export EAP_APP_AMQ_TCP_SERVICE_PORT=61616
    export MQ_JNDI=java:/DefaultJMSConnectionFactory
    export MQ_USERNAME=adminUser
    export MQ_PASSWORD=adminPassword
    export MQ_PROTOCOL=tcp
    export MQ_QUEUES=HELLOWORLDMDBQueue
    export MQ_TOPICS=HELLOWORLDMDBTopic
    export DEFAULT_JMS_CONNECTION_FACTORY=java:/defaultJmsConnectionFactory
    echo '<test-content>' > ${CONFIG_FILE}
    echo '<!-- ##RESOURCE_ADAPTERS## -->' >> ${CONFIG_FILE}
    echo "<default-bindings jms-connection-factory=\"##DEFAULT_JMS##\"/>" >> ${CONFIG_FILE}
    echo '</test-content>' >> ${CONFIG_FILE}
    run inject_brokers
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result:   ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Inject brokers - 3 x AMQ 6" {
    expected=$(cat  $BATS_TEST_DIRNAME/standalone-openshift-configure-mq-amq6-multiple-ra.xml| xmllint --format --noblanks -)
    # AMQ6: "eap-app-amq=MQ" the -amq indicates this is AMQ6

    export MQ_SERVICE_PREFIX_MAPPING="eap-mq1-amq=MQ1, eap-mq2-amq=MQ2, eap-mq3-amq=MQ3"
    export EAP_MQ1_AMQ_TCP_SERVICE_HOST=localhostMQ1
    export EAP_MQ1_AMQ_TCP_SERVICE_PORT=61616
    export MQ1_JNDI=java:/MQ1JMSConnectionFactory
    export MQ1_USERNAME=adminUserMQ1
    export MQ1_PASSWORD=adminPasswordMQ1
    export MQ1_PROTOCOL=tcp
    export MQ1_QUEUES=HELLOWORLDMDBQueueMQ1
    export MQ1_TOPICS=HELLOWORLDMDBTopicMQ1

    export EAP_MQ2_AMQ_TCP_SERVICE_HOST=localhostMQ2
    export EAP_MQ2_AMQ_TCP_SERVICE_PORT=61616
    export MQ2_JNDI=java:/MQ2JMSConnectionFactory
    export MQ2_USERNAME=adminUserMQ2
    export MQ2_PASSWORD=adminPasswordMQ2
    export MQ2_PROTOCOL=tcp
    export MQ2_QUEUES=HELLOWORLDMDBQueueMQ2
    export MQ2_TOPICS=HELLOWORLDMDBTopicMQ2

    export EAP_MQ3_AMQ_TCP_SERVICE_HOST=localhostMQ3
    export EAP_MQ3_AMQ_TCP_SERVICE_PORT=61616
    export MQ3_JNDI=java:/MQ3JMSConnectionFactory
    export MQ3_USERNAME=adminUserMQ3
    export MQ3_PASSWORD=adminPasswordMQ3
    export MQ3_PROTOCOL=tcp
    export MQ3_QUEUES=HELLOWORLDMDBQueueMQ3
    export MQ3_TOPICS=HELLOWORLDMDBTopicMQ3

    export DEFAULT_JMS_CONNECTION_FACTORY=java:/MQ1JMSConnectionFactory
    echo '<test-content>' > ${CONFIG_FILE}
    echo '<!-- ##RESOURCE_ADAPTERS## -->' >> ${CONFIG_FILE}
    echo "<default-bindings jms-connection-factory=\"##DEFAULT_JMS##\"/>" >> ${CONFIG_FILE}
    echo '</test-content>' >> ${CONFIG_FILE}
    run inject_brokers
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result:   ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Inject brokers - AMQ 7 - remote" {
    expected=$(cat  $BATS_TEST_DIRNAME/standalone-openshift-configure-mq-amq7-remote.xml | xmllint --format --noblanks -)
    # AMQ 7: "eap-app-amq7=MQ" the -amq indicates this is AMQ7
    # example config:
    # MQ_SERVICE_PREFIX_MAPPING="eap-app-amq=MQ"
    # MQ_USERNAME=admin
    # MQ_PASSWORD=admin
    # MQ_PROTOCOL=tcp
    # MQ_QUEUES=HELLOWORLDMDBQueue
    # MQ_TOPICS=HELLOWORLDMDBTopic

    export MQ_SERVICE_PREFIX_MAPPING="eap-app-amq7=MQ"
    export EAP_APP_AMQ_TCP_SERVICE_HOST=localhost
    export EAP_APP_AMQ_TCP_SERVICE_PORT=61616
    export MQ_JNDI=java:/ConnectionFactory
    export MQ_USERNAME=adminUser
    export MQ_PASSWORD=adminPassword
    export MQ_PROTOCOL=tcp
    export MQ_QUEUES=HELLOWORLDMDBQueue
    export MQ_TOPICS=HELLOWORLDMDBTopic

    echo '<test-content>' > ${CONFIG_FILE}
    echo '<!-- ##AMQ_REMOTE_CONNECTOR## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_POOLED_CONNECTION_FACTORY## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_MESSAGING_SOCKET_BINDING## -->' >> ${CONFIG_FILE}
    echo "<default-bindings jms-connection-factory=\"##DEFAULT_JMS##\"/>" >> ${CONFIG_FILE}
    echo '</test-content>' >> ${CONFIG_FILE}
    run inject_brokers
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result:   ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Inject brokers - 3 x AMQ 7 - remote" {
    expected=$(cat  $BATS_TEST_DIRNAME/standalone-openshift-configure-mq-amq7-remote-multiple.xml | xmllint --format --noblanks -)
    # AMQ 7: "eap-app-amq7=MQ" the -amq indicates this is AMQ7

    export MQ_SERVICE_PREFIX_MAPPING="eap-mq1-amq7=MQ1, eap-mq2-amq7=MQ2, eap-mq3-amq7=MQ3"
    export EAP_MQ1_AMQ_TCP_SERVICE_HOST=localhostMQ1
    export EAP_MQ1_AMQ_TCP_SERVICE_PORT=61616
    export MQ1_JNDI=java:/MQ1ConnectionFactory
    export MQ1_USERNAME=adminUserMQ1
    export MQ1_PASSWORD=adminPasswordMQ1
    export MQ1_PROTOCOL=tcp
    export MQ1_QUEUES=HELLOWORLDMDBQueueMQ1
    export MQ1_TOPICS=HELLOWORLDMDBTopicMQ1

    export EAP_MQ2_AMQ_TCP_SERVICE_HOST=localhostMQ2
    export EAP_MQ2_AMQ_TCP_SERVICE_PORT=61616
    export MQ2_JNDI=java:/MQ2ConnectionFactory
    export MQ2_USERNAME=adminUserMQ2
    export MQ2_PASSWORD=adminPasswordMQ2
    export MQ2_PROTOCOL=tcp
    export MQ2_QUEUES=HELLOWORLDMDBQueueMQ2
    export MQ2_TOPICS=HELLOWORLDMDBTopicMQ2

    export EAP_MQ3_AMQ_TCP_SERVICE_HOST=localhostMQ3
    export EAP_MQ3_AMQ_TCP_SERVICE_PORT=61616
    export MQ3_JNDI=java:/MQ3ConnectionFactory
    export MQ3_USERNAME=adminUserMQ3
    export MQ3_PASSWORD=adminPasswordMQ3
    export MQ3_PROTOCOL=tcp
    export MQ3_QUEUES=HELLOWORLDMDBQueueMQ3
    export MQ3_TOPICS=HELLOWORLDMDBTopicMQ3

    export DEFAULT_JMS_CONNECTION_FACTORY="java:/MQ2ConnectionFactory"

    echo '<test-content>' > ${CONFIG_FILE}
    echo '<!-- ##AMQ_REMOTE_CONNECTOR## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_POOLED_CONNECTION_FACTORY## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_EXTERNAL_JMS_OBJECTS## -->' >> ${CONFIG_FILE}
    echo '<!-- ##AMQ_MESSAGING_SOCKET_BINDING## -->' >> ${CONFIG_FILE}
    echo "<default-bindings jms-connection-factory=\"##DEFAULT_JMS##\"/>" >> ${CONFIG_FILE}
    echo '</test-content>' >> ${CONFIG_FILE}
    run inject_brokers
    result=$(cat ${CONFIG_FILE} | xmllint --format --noblanks -)
    echo "Result:   ${result}"
    echo "Expected: ${expected}"
    [ "${result}" = "${expected}" ]
}

@test "Generate External JMS Queue" {
    expected='<external-jms-queue name="myqueue" entries="java:/jms/connectorName/myqueue myqueue"/>'
    run generate_external_jms_lookup "queue" "connectorName" "myqueue"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate External JMS Topic" {
    expected='<external-jms-topic name="mytopic" entries="java:/jms/connectorName/mytopic mytopic"/>'
    run generate_external_jms_lookup "topic" "connectorName" "mytopic"
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}

@test "Generate External JMS Queue - no name" {
    expected="<!-- Error: name is required for external JMS object -->"
    run generate_external_jms_lookup "queue" "connector_name" ""
    echo "Result:   ${output}"
    echo "Expected: ${expected}"
    [ "${output}" = "${expected}" ]
}
