@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: Common EAP tests

  Scenario: Check for add-user failures
    When container is ready
    Then container log should contain Running jboss-eap-7
     And available container log should not contain AddUserFailedException

  Scenario: Cloud-1784, make the Access Log Valve configurable
    When container is started with env
      | variable          | value                 |
      | ENABLE_ACCESS_LOG | true                  |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <access-log pattern="%h %l %u %t %{i,X-Forwarded-Host} &quot;%r&quot; %s %b" use-server-log="true"/>

  Scenario: Management interface is secured and JAVA_OPTS is modified
    When container is started with env
       | variable                | value             |
       | ADMIN_USERNAME          | admin2            |
       | ADMIN_PASSWORD          | lollerskates11$   |
       | JAVA_OPTS_APPEND        | -Dfoo=bar         |
    Then container log should contain WFLYSRV0025
     And run /opt/eap/bin/jboss-cli.sh -c --error-on-interact --no-local-auth --user=admin2 --password=lollerskates11$ :whoami in container and immediately check its output contains admin2
     # We expect this command to fail, so make sure the return code is zero, we're interested only in output here
     And run sh -c '/opt/eap/bin/jboss-cli.sh -c --error-on-interact --no-local-auth deployment-info || true' in container and immediately check its output contains Unable to authenticate
     And container log should contain -Dfoo=bar

  # https://issues.jboss.org/browse/CLOUD-587 (security realm for management API)
  # CLOUD-834 (probe rework) uses http interface, which cannot use "local" user,
  #     even when the request originates from localhost, which is how jboss-cli
  #     works.  Note too that http interface is only bound to localhost.
  #     setting to @ignore for now.
  # For EAP 7.0 and derived images
  Scenario: Management interface is secured (no warning message)
    When container is ready
    # The below should complete faster than 'should not contain' alone
    # this is the key for the "JBoss EAP 7.a.b.GA (WildFly Core x.y.z.Final-redhat-1) started" message
    Then container log should contain WFLYSRV0025
     And available container log should not contain No security realm defined for http management service; all access will be unrestricted.

  @ignore @jboss-eap-7-tech-preview/eap72-openjdk11-openshift @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  Scenario: Java 1.8 is installed and set as default one
    When container is ready
    Then run java -version in container and check its output for openjdk version "1.8.0"
    Then run javac -version in container and check its output for javac 1.8.0

  @ignore @jboss-eap-7-tech-preview
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Java 11 is installed and set as default one
    When container is ready
    Then run java -version in container and check its output for openjdk version "11.0.
    Then run javac -version in container and check its output for javac 11.0.

  Scenario: readinessProbe runs successfully
    When container is ready
    Then run /opt/eap/bin/readinessProbe.sh in container once
    Then run /opt/eap/bin/livenessProbe.sh in container once

  @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  # https://issues.jboss.org/browse/CLOUD-204
  Scenario: Check if kube ping protocol is used by default
    When container is ready
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='openshift.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='openshift.DNS_PING']

  @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if kube ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.KUBE_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='openshift.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='openshift.DNS_PING']

  @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if dns ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.DNS_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]

  Scenario: Check if jolokia is configured correctly
    When container is ready
    Then container log should contain -javaagent:/opt/jboss/container/jolokia/jolokia.jar=config=/opt/jboss/container/jolokia/etc/jolokia.properties

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  # https://issues.jboss.org/browse/CLOUD-295
  # https://issues.jboss.org/browse/CLOUD-336
  Scenario: Check if jgroups is secure
    When container is started with env
       | variable                 | value    |
       | JGROUPS_CLUSTER_PASSWORD | asdfasdf |
       | JGROUPS_ENCRYPT_SECRET                       | eap_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
       | JGROUPS_PING_PROTOCOL                        | openshift.DNS_PING                     |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='auth-protocol'][@type='AUTH']

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups AUTH protocol is disabled when using SYM_ENCRYPT and JGROUPS_CLUSTER_PASSWORD undefined
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='AUTH']
     And container log should contain WARN No password defined for JGroups cluster. AUTH protocol will be disabled. Please define JGROUPS_CLUSTER_PASSWORD.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with encrypt secret undefined
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
    Then container log should contain WARN Detected missing JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing name
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing password
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption does not create invalid configuration when using SYM_ENCRYPT with missing keystore file
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_PROTOCOL                     | SYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption requires AUTH protocol to be set when using ASYM_ENCRYPT protocol
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_PING_PROTOCOL                        | openshift.DNS_PING                      |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping                                    |
    Then container log should contain WARN JGROUPS_ENCRYPT_PROTOCOL=ASYM_ENCRYPT requires JGROUPS_CLUSTER_PASSWORD to be set and not empty, the communication within the cluster WILL NOT be encrypted.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_SECRET defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret              |
       | JGROUPS_PING_PROTOCOL                        | dns.DNS_PING                            |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping-service                            |
       | JGROUPS_CLUSTER_PASSWORD                     | P@ssw0rd                                |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster will be encrypted using a deprecated version of ASYM_ENCRYPT protocol. You need to set all of these variables to configure ASYM_ENCRYPT using the Elytron keystore: JGROUPS_ENCRYPT_SECRET, JGROUPS_ENCRYPT_NAME, JGROUPS_ENCRYPT_PASSWORD, JGROUPS_ENCRYPT_KEYSTORE.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_NAME defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                   |
       | JGROUPS_PING_PROTOCOL                        | dns.DNS_PING                            |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping-service                            |
       | JGROUPS_CLUSTER_PASSWORD                     | P@ssw0rd                                |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster will be encrypted using a deprecated version of ASYM_ENCRYPT protocol. You need to set all of these variables to configure ASYM_ENCRYPT using the Elytron keystore: JGROUPS_ENCRYPT_SECRET, JGROUPS_ENCRYPT_NAME, JGROUPS_ENCRYPT_PASSWORD, JGROUPS_ENCRYPT_KEYSTORE.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_PASSWORD defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                          |
       | JGROUPS_PING_PROTOCOL                        | dns.DNS_PING                            |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping-service                            |
       | JGROUPS_CLUSTER_PASSWORD                     | P@ssw0rd                                |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster will be encrypted using a deprecated version of ASYM_ENCRYPT protocol. You need to set all of these variables to configure ASYM_ENCRYPT using the Elytron keystore: JGROUPS_ENCRYPT_SECRET, JGROUPS_ENCRYPT_NAME, JGROUPS_ENCRYPT_PASSWORD, JGROUPS_ENCRYPT_KEYSTORE.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_KEYSTORE_DIR defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume      |
       | JGROUPS_PING_PROTOCOL                        | dns.DNS_PING                            |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping-service                            |
       | JGROUPS_CLUSTER_PASSWORD                     | P@ssw0rd                                |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster will be encrypted using a deprecated version of ASYM_ENCRYPT protocol. You need to set all of these variables to configure ASYM_ENCRYPT using the Elytron keystore: JGROUPS_ENCRYPT_SECRET, JGROUPS_ENCRYPT_NAME, JGROUPS_ENCRYPT_PASSWORD, JGROUPS_ENCRYPT_KEYSTORE.

  @redhat-sso-7-tech-preview/sso-cd-openshift @redhat-sso-7/sso73-openshift
  Scenario: Check jgroups encryption issues a warning when using ASYM_ENCRYPT with JGROUPS_ENCRYPT_KEYSTORE file defined
    When container is started with env
       | variable                                     | value                                   |
       | JGROUPS_ENCRYPT_PROTOCOL                     | ASYM_ENCRYPT                            |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                            |
       | JGROUPS_PING_PROTOCOL                        | dns.DNS_PING                            |
       | OPENSHIFT_DNS_PING_SERVICE_NAME              | ping-service                            |
       | JGROUPS_CLUSTER_PASSWORD                     | P@ssw0rd                                |
    Then container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster will be encrypted using a deprecated version of ASYM_ENCRYPT protocol. You need to set all of these variables to configure ASYM_ENCRYPT using the Elytron keystore: JGROUPS_ENCRYPT_SECRET, JGROUPS_ENCRYPT_NAME, JGROUPS_ENCRYPT_PASSWORD, JGROUPS_ENCRYPT_KEYSTORE.
  # CD doesn't have these any more
  @ignore @jboss-eap-7-tech-preview
  Scenario: No duplicate module jars
    When container is ready
    Then files at /opt/eap/modules/system/layers/openshift/org/jgroups/main should have count of 2

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

  Scenario: EJB transaction recovery
    When container is started with env
      | variable                                    | value                     |
      | STATEFULSET_HEADLESS_SERVICE_NAME           | tx-server-headless        |
    Then container log should contain WFLYSRV0025
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()="socket-binding"][@name="http"]/*[local-name()="client-mapping" and substring(@destination-address,string-length(@destination-address) - string-length("tx-server-headless") + 1) = "tx-server-headless"]
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()="socket-binding"][@name="https"]/*[local-name()="client-mapping" and substring(@destination-address,string-length(@destination-address) - string-length("tx-server-headless") + 1) = "tx-server-headless"]

  # https://issues.jboss.org/browse/CLOUD-204
  Scenario: Check if kube ping protocol is used by default
    When container is ready
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='kubernetes.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='protocol'][@type='dns.DNS_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]

  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if kube ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.KUBE_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='kubernetes.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="dns.DNS_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]

  # https://issues.jboss.org/browse/CLOUD-1958
  Scenario: Check if dns ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | openshift.DNS_PING     |
      | OPENSHIFT_DNS_PING_SERVICE_NAME      | ping                   |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()="protocol"][@type="dns.DNS_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="kubernetes.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]

    Scenario: Check if kube ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | kubernetes.KUBE_PING     |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='kubernetes.KUBE_PING']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="dns.DNS_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]

  Scenario: Check if dns ping protocol is used when specified
    When container is started with env
      | variable                             | value           |
      | JGROUPS_PING_PROTOCOL                | dns.DNS_PING    |
      | OPENSHIFT_DNS_PING_SERVICE_NAME      | ping            |
    # 2 matches, one for TCP, one for UDP
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()="protocol"][@type="dns.DNS_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="kubernetes.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.KUBE_PING"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()="protocol"][@type="openshift.DNS_PING"]

  # CD doesn't have these any more, count should be 0
  Scenario: No duplicate module jars
    When container is ready
    Then file at /opt/eap/modules/system/layers/openshift/org/jgroups/main should not exist

 Scenario: readinessProbe runs successfully on cloud-server trimmed server
   Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                        | value                                                                                  |
    | GALLEON_PROVISION_LAYERS        | cloud-server |
   Then container log should contain WFLYSRV0025
   Then run /opt/eap/bin/readinessProbe.sh in container once
   Then run /opt/eap/bin/livenessProbe.sh in container once
