@jboss-eap-6
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
    Then s2i build log should contain Copying app data from configuration to /opt/eap/standalone/data
    And run ls /opt/eap/standalone/data/standalone-openshift.xml in container and check its output for /opt/eap/standalone/data/standalone-openshift.xml

  # https://issues.jboss.org/browse/CLOUD-1168
  Scenario: Test DATA_DIR with DATA_DIR and APP_DATADIR set, DATA_DIR is not existing
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable    | value                         |
       | APP_DATADIR | modules/org/postgresql94/main |
       | DATA_DIR    | /tmp/test                     |
    Then s2i build log should contain Copying app data from modules/org/postgresql94/main to /tmp/test...
     And run ls /tmp/test/module.xml in container and check its output for /tmp/test/module.xml

  # https://issues.jboss.org/browse/CLOUD-1168
  Scenario: Test DATA_DIR with DATA_DIR and APP_DATADIR set, DATA_DIR is existing and not owned by the user
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable    | value                         |
       | APP_DATADIR | modules/org/postgresql94/main |
       | DATA_DIR    | /tmp                          |
    Then s2i build log should contain Copying app data from modules/org/postgresql94/main to /tmp...
     And run ls /tmp/module.xml in container and check its output for /tmp/module.xml

  # https://issues.jboss.org/browse/CLOUD-483
  Scenario: Test setting ARTIFACT_DIR to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable     | value       |
       | ARTIFACT_DIR |             |
    Then container log should contain Deployed "jboss-helloworld.war"

  Scenario: Set HTTPS_NAME to null
    Given XML namespaces
      | prefix | url                      |
      | ns     | urn:jboss:domain:web:2.2 |
    When container is started with env
      | variable               | value                        |
      | EAP_HTTPS_NAME         | eap-test-https-name          |
      | EAP_HTTPS_PASSWORD     | eap-test-https-password      |
      | EAP_HTTPS_KEYSTORE_DIR | eap-test-https-keystore-dir  |
      | EAP_HTTPS_KEYSTORE     | eap-test-https-keystore      |
      | HTTPS_NAME             |                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:connector[@name='https']/ns:ssl[@name='eap-test-https-name']

  Scenario: Set HTTPS_PASSWORD to null
    Given XML namespaces
      | prefix | url                      |
      | ns     | urn:jboss:domain:web:2.2 |
    When container is started with env
      | variable               | value                        |
      | EAP_HTTPS_NAME         | eap-test-https-name          |
      | EAP_HTTPS_PASSWORD     | eap-test-https-password      |
      | EAP_HTTPS_KEYSTORE_DIR | eap-test-https-keystore-dir  |
      | EAP_HTTPS_KEYSTORE     | eap-test-https-keystore      |
      | HTTPS_PASSWORD         |                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:connector[@name='https']/ns:ssl[@password='eap-test-https-password']

  Scenario: Set HTTPS_KEYSTORE_DIR to null
    Given XML namespaces
      | prefix | url                      |
      | ns     | urn:jboss:domain:web:2.2 |
    When container is started with env
      | variable               | value                        |
      | EAP_HTTPS_NAME         | eap-test-https-name          |
      | EAP_HTTPS_PASSWORD     | eap-test-https-password      |
      | EAP_HTTPS_KEYSTORE_DIR | eap-test-https-keystore-dir  |
      | EAP_HTTPS_KEYSTORE     | eap-test-https-keystore      |
      | HTTPS_KEYSTORE_DIR     |                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:connector[@name='https']/ns:ssl[@certificate-key-file='eap-test-https-keystore-dir/eap-test-https-keystore']

  Scenario: Set HTTPS_KEYSTORE to null
    Given XML namespaces
      | prefix | url                      |
      | ns     | urn:jboss:domain:web:2.2 |
    When container is started with env
      | variable               | value                        |
      | EAP_HTTPS_NAME         | eap-test-https-name          |
      | EAP_HTTPS_PASSWORD     | eap-test-https-password      |
      | EAP_HTTPS_KEYSTORE_DIR | eap-test-https-keystore-dir  |
      | EAP_HTTPS_KEYSTORE     | eap-test-https-keystore      |
      | HTTPS_KEYSTORE         |                              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:connector[@name='https']/ns:ssl[@certificate-key-file='eap-test-https-keystore-dir/eap-test-https-keystore']

  Scenario: Set EAP_SECDOMAIN_USERS_PROPERTIES to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable                       | value                        |
      | EAP_SECDOMAIN_NAME             | eap-secdomain-name           |
      | EAP_SECDOMAIN_USERS_PROPERTIES |                              |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']/ns:authentication/ns:login-module/ns:module-option[@name='usersProperties' and @value='${jboss.server.config.dir}/users.properties']

  Scenario: Set SECDOMAIN_USERS_PROPERTIES to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable                   | value                        |
      | EAP_SECDOMAIN_NAME         | eap-secdomain-name           |
      | SECDOMAIN_USERS_PROPERTIES |                              |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']/ns:authentication/ns:login-module/ns:module-option[@name='usersProperties' and @value='${jboss.server.config.dir}/users.properties']

  Scenario: Set EAP_SECDOMAIN_ROLES_PROPERTIES to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable                       | value                        |
      | EAP_SECDOMAIN_NAME             | eap-secdomain-name           |
      | EAP_SECDOMAIN_ROLES_PROPERTIES |                              |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']/ns:authentication/ns:login-module/ns:module-option[@name='rolesProperties' and @value='${jboss.server.config.dir}/roles.properties']

  Scenario: Set SECDOMAIN_ROLES_PROPERTIES to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable                   | value                        |
      | EAP_SECDOMAIN_NAME         | eap-secdomain-name           |
      | SECDOMAIN_ROLES_PROPERTIES |                              |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']/ns:authentication/ns:login-module/ns:module-option[@name='rolesProperties' and @value='${jboss.server.config.dir}/roles.properties']

  Scenario: Set SECDOMAIN_NAME to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable               | value                        |
      | EAP_SECDOMAIN_NAME     | eap-secdomain-name           |
      | SECDOMAIN_NAME         |                              |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']

  Scenario: Set SECDOMAIN_PASSWORD_STACKING to null
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
      | variable                        | value                           |
      | EAP_SECDOMAIN_NAME              | eap-secdomain-name              |
      | EAP_SECDOMAIN_PASSWORD_STACKING | eap-secdomain-password-stacking |
      | SECDOMAIN_PASSWORD_STACKING     |                                 |
    And XML namespaces
      | prefix | url                           |
      | ns     | urn:jboss:domain:security:1.2 |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //ns:security-domain[@name='eap-secdomain-name']/ns:authentication/ns:login-module/ns:module-option[@name='password-stacking']

