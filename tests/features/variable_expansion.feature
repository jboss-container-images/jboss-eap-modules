@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: Check correct variable expansion used
  Scenario: Set EAP_ADMIN_USERNAME to null
    When container is started with env
      | variable           | value                            |
      | EAP_ADMIN_PASSWORD | p@ssw0rd                         |
      | EAP_ADMIN_USERNAME |                                  |
    Then container log should contain Added user 'eapadmin' to file '/opt/eap/standalone/configuration/mgmt-users.properties'

  Scenario: Set ADMIN_USERNAME to null
    When container is started with env
      | variable           | value                            |
      | EAP_ADMIN_PASSWORD | p@ssw0rd                         |
      | ADMIN_USERNAME     |                                  |
    Then container log should contain Added user 'eapadmin' to file '/opt/eap/standalone/configuration/mgmt-users.properties'

  Scenario: Set ADMIN_PASSWORD to null
    When container is started with env
      | variable           | value                            |
      | EAP_ADMIN_PASSWORD | p@ssw0rd                         |
      | ADMIN_PASSWORD     |                                  |
    Then container log should contain Added user 'eapadmin' to file '/opt/eap/standalone/configuration/mgmt-users.properties'

  Scenario: Set ADMIN_PASSWORD but not ADMIN_USERNAME
    When container is started with env
      | variable           | value                            |
      | ADMIN_PASSWORD     | GoP@ts6!                         |
    Then container log should contain Added user 'eapadmin' to file '/opt/eap/standalone/configuration/mgmt-users.properties'

  Scenario: Set NODE_NAME to null
    When container is started with env
      | variable           | value                            |
      | EAP_NODE_NAME      | eap-test-node-name               |
      | NODE_NAME          |                                  |
    Then container log should contain jboss.node.name = eap-test-node-name

  Scenario: Test setting DATA_DIR to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable    | value         |
       | APP_DATADIR | configuration |
       | DATA_DIR    |               |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.target=1.8 -Dmaven.compiler.source=1.8 -Dversion.war.plugin=3.3.2 |
    Then s2i build log should contain Copying app data from configuration to /opt/eap/standalone/data
    And run ls /opt/eap/standalone/data/standalone-openshift.xml in container and check its output for /opt/eap/standalone/data/standalone-openshift.xml

  # https://issues.jboss.org/browse/CLOUD-1168
  Scenario: Test DATA_DIR with DATA_DIR and APP_DATADIR set, DATA_DIR is not existing
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable    | value                         |
       | APP_DATADIR | modules/org/postgresql94/main |
       | DATA_DIR    | /tmp/test                     |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.target=1.8 -Dmaven.compiler.source=1.8 -Dversion.war.plugin=3.3.2 |
    Then s2i build log should contain Copying app data from modules/org/postgresql94/main to /tmp/test...
     And run ls /tmp/test/module.xml in container and check its output for /tmp/test/module.xml

  # https://issues.jboss.org/browse/CLOUD-1168
  Scenario: Test DATA_DIR with DATA_DIR and APP_DATADIR set, DATA_DIR is existing and not owned by the user
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable    | value                         |
       | APP_DATADIR | modules/org/postgresql94/main |
       | DATA_DIR    | /tmp                          |
       | MAVEN_ARGS_APPEND |  -Dmaven.compiler.target=1.8 -Dmaven.compiler.source=1.8 -Dversion.war.plugin=3.3.2 |
    Then s2i build log should contain Copying app data from modules/org/postgresql94/main to /tmp...
     And run ls /tmp/module.xml in container and check its output for /tmp/module.xml
