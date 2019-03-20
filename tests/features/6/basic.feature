@jboss-eap-6
Feature: Openshift EAP common tests (EAP and EAP derived images)

  Scenario: Management interface is secured and JAVA_OPTS is modified
    When container is started with env
       | variable                    | value             |
       | ADMIN_USERNAME          | admin2            |
       | ADMIN_PASSWORD          | lollerskates11$   |
       | JAVA_OPTS_APPEND            | -Dfoo=bar         |
    Then container log should contain JBAS015874
     And run /opt/eap/bin/jboss-cli.sh -c --no-local-auth --user=admin2 --password=lollerskates11$ deployment-info in container and immediately check its output contains activemq-rar
     # We expect this command to fail, so make sure the return code is zero, we're interested only in output here
     And run sh -c '/opt/eap/bin/jboss-cli.sh -c --no-local-auth --user=wronguser --password=wrongpass deployment-info || true' in container and immediately check its output contains Authentication failed
     And container log should contain -Dfoo=bar

  # https://issues.jboss.org/browse/CLOUD-587 (security realm for management API)
  # CLOUD-834 (probe rework) uses http interface, which cannot use "local" user,
  #     even when the request originates from localhost, which is how jboss-cli
  #     works.  Note too that http interface is only bound to localhost.
  #     setting to @ignore for now.
  # For EAP 6.4 and derived images
  @ignore
  Scenario: Management interface is secured (no warning message)
    When container is ready
    # The below should complete faster than 'should not contain' alone
    # this is the key for the "JBoss EAP 6.a.b.GA (AS x.y.z.Final-redhat-4) started" message
    Then container log should contain JBAS015874
     And available container log should not contain No security realm defined for http management service; all access will be unrestricted.

  Scenario: Java 1.8 is installed and set as default one
    When container is ready
    Then run java -version in container and check its output for openjdk version "1.8.0
    Then run javac -version in container and check its output for javac 1.8.0

  # test readinessProbe and livenessProbe (CLOUD-612)
  Scenario: readinessProbe runs successfully
    When container is ready
    Then run /opt/eap/bin/readinessProbe.sh in container once
    Then run /opt/eap/bin/livenessProbe.sh in container once

  # https://issues.jboss.org/browse/CLOUD-204
  Scenario: Check if kube ping protocol is used by default
    When container is ready
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='openshift.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='openshift.DNS_PING']

  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if kube ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.KUBE_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='openshift.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='openshift.DNS_PING']

  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if dns ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.DNS_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='openshift.DNS_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='openshift.KUBE_PING']

  Scenario: Check if jolokia is configured correctly
    When container is ready
    Then container log should contain -javaagent:/opt/jboss/container/jolokia/jolokia.jar=config=/opt/jboss/container/jolokia/etc/jolokia.properties

  Scenario: jgroups-encrypt
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_SECRET                       | eap_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
       | JGROUPS_PING_PROTOCOL                        | openshift.DNS_PING                     |
       | JGROUPS_CLUSTER_PASSWORD                     | asdasdasdasdgfd                        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /etc/jgroups-encrypt-secret-volume/keystore.jks on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='keystore_name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jboss on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='alias']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mykeystorepass on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='store_password']
     # https://issues.jboss.org/browse/CLOUD-1192
     # https://issues.jboss.org/browse/CLOUD-1196
     # Make sure the SYM_ENCRYPT protocol is specified before pbcast.NAKACK for udp stack
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pbcast.NAKACK on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/following-sibling::*[1]/@type
     # Make sure the SYM_ENCRYPT protocol is specified before pbcast.NAKACK for tcp stack
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pbcast.NAKACK on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/following-sibling::*[1]/@type

  # https://issues.jboss.org/browse/CLOUD-295
  # https://issues.jboss.org/browse/CLOUD-336
  Scenario: Check if jgroups is secure
    When container is started with env
       | variable                 | value    |
       | JGROUPS_CLUSTER_PASSWORD | asdfasdf |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='AUTH']

  Scenario: Check jgroups AUTH protocol is disabled when using SYM_ENCRYPT and JGROUPS_CLUSTER_PASSWORD undefined
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='AUTH']
     And container log should contain WARN No password defined for JGroups cluster. AUTH protocol will be disabled. Please define JGROUPS_CLUSTER_PASSWORD.

  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with encrypt secret undefined
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
    Then container log should contain WARN Detected missing JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing name
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing password
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing keystore dir
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing keystore file
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption requires AUTH protocol to be set when using ASYM_ENCRYPT protocol
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
    Then container log should contain WARN No password defined for JGroups cluster. AUTH protocol is required when using JGroups ASYM_ENCRYPT cluster traffic encryption protocol.

  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_SECRET defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret              |
    Then container log should contain WARN The specified JGroups SYM_ENCRYPT JCEKS keystore definition will be ignored when using ASYM_ENCRYPT.

  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_NAME defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                   |
    Then container log should contain WARN The specified JGroups SYM_ENCRYPT JCEKS keystore definition will be ignored when using ASYM_ENCRYPT.

  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_PASSWORD defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                          |
    Then container log should contain WARN The specified JGroups SYM_ENCRYPT JCEKS keystore definition will be ignored when using ASYM_ENCRYPT.

  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_KEYSTORE_DIR defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume      |
    Then container log should contain WARN The specified JGroups SYM_ENCRYPT JCEKS keystore definition will be ignored when using ASYM_ENCRYPT.

  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_KEYSTORE file defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                            |
    Then container log should contain WARN The specified JGroups SYM_ENCRYPT JCEKS keystore definition will be ignored when using ASYM_ENCRYPT.

  Scenario: No duplicate module jars
    When container is ready
    Then files at /opt/eap/modules/system/layers/openshift/org/jgroups/main should have count of 2

  Scenario: Ensure transaction node name is set and we use urandom
    When container is ready
    Then container log should contain JBAS015874:
    And available container log should not contain JBAS010153: Node identifier property is set to the default value. Please make sure it is unique.
    And available container log should contain -Djava.security.egd

  Scenario: jboss.modules.system.pkgs is set to defaults when JBOSS_MODULES_SYSTEM_PKGS_APPEND env var is not set
    When container is ready
    Then container log should contain VM Arguments:
     And available container log should contain -Djboss.modules.system.pkgs=org.jboss.logmanager,jdk.nashorn.api,com.sun.crypto.provider

  Scenario: jboss.modules.system.pkgs will contain default value and the value of JBOSS_MODULES_SYSTEM_PKGS_APPEND env var, when it is set
    When container is started with env
      | variable                             | value           |
      | JBOSS_MODULES_SYSTEM_PKGS_APPEND     | org.foo.bar     |
    Then container log should contain VM Arguments:
     And available container log should contain -Djboss.modules.system.pkgs=org.jboss.logmanager,jdk.nashorn.api,com.sun.crypto.provider,org.foo.bar

  Scenario: check ownership when started as alternative UID
    When container is started as uid 26458
    Then container log should contain Running
     And run id -u in container and check its output contains 26458
     And all files under /opt/eap are writeable by current user
     And all files under /deployments are writeable by current user

  Scenario: HTTP proxy as java properties (CLOUD-865) and disable web console (CLOUD-1040)
    When container is started with env
      | variable   | value                 |
      | HTTP_PROXY | http://localhost:1337 |
    Then container log should contain Admin console is not enabled
     And container log should contain VM Arguments:
     And available container log should contain http.proxyHost = localhost
     And available container log should contain http.proxyPort = 1337

  @ci
  Scenario: Check that the jboss-eap-6/eap64-openshift image contains 6 layers
    Given image is built
     Then image should contain 6 layers

  # https://issues.jboss.org/browse/CLOUD-180
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain Running jboss-eap-6/eap64-openshift image, version

  Scenario: Check that the labels are correctly set
    Given image is built
     Then the image should contain label com.redhat.component with value jboss-eap-6-eap64-openshift-container
      And the image should contain label name with value jboss-eap-6/eap64-openshift
      And the image should contain label io.openshift.expose-services with value 8080:http
      And the image should contain label io.openshift.tags with value builder,javaee,eap,eap6

  Scenario: Check for add-user failures
    When container is ready
    Then container log should contain Running jboss-eap-6/eap64-openshift image
     And available container log should not contain AddUserFailedException

  Scenario: CLOUD-437 - ignore MaxPermSize with Java 8
    When container is ready
    Then container log should contain JBAS015874
     And available container log should not contain ignoring option MaxPermSize=256m

  Scenario: CLOUD-237 - DEBUG enabled in standalone.sh
    When container is ready
    Then file /opt/eap/bin/standalone.sh should contain DEBUG_MODE="${DEBUG:-false} 
      And file /opt/eap/bin/standalone.sh should contain DEBUG_PORT="${DEBUG_PORT:-8787}"

  Scenario: CLOUD-1784, make the Access Log Valve configurable
    When container is started with env
      | variable          | value                 |
      | ENABLE_ACCESS_LOG | true                  |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <valve name="accessLog" module="org.jboss.openshift" class-name="org.jboss.openshift.valves.StdoutAccessLogValve">
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <param param-name="pattern" param-value="%h %l %u %t %{X-Forwarded-Host}i &quot;%r&quot; %s %b" />
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain </valve>
