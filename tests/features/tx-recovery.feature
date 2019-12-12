@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift transaction scaledown recovery on partition PV

Scenario: Cannot connect to an Oracle database with transaction JDBC object store scaledown processing
    When container is started with command bash
       | variable                         | value                                 |
       | JDBC_SKIP_RECOVERY               | false                                 |
       | TX_DATABASE_PREFIX_MAPPING       | TEST_ORACLE                           |
       | TEST_ORACLE_JNDI                 | java:/jboss/datasources/testds        |
       | TEST_ORACLE_USERNAME             | txnuser                               |
       | TEST_ORACLE_PASSWORD             | txnpassword                           |
       | TEST_ORACLE_SERVICE_HOST         | 10.1.1.1                              |
       | TEST_ORACLE_SERVICE_PORT         | 1521                                  |
       | TEST_ORACLE_DATABASE             | XE                                    |
       | JDBC_RECOVERY_CUSTOM_JDBC_MODULE | com.oracle.ojdbc                      |
       | NODE_NAME                        | Test-Store-Node-Name                  |
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-jdbc-store-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-jdbc-store-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And file /opt/eap/modules/system/layers/openshift/io/narayana/openshift-recovery/jdbc/main/module.xml should contain com.oracle.ojdbc
    And file /tmp/boot.log should contain java.lang.ClassNotFoundException: Could not load requested class : oracle.jdbc.driver.OracleDriver

Scenario: Fail to run jdbc recovery when unknown database type is specified
    When container is started with command bash
       | variable                     | value                                    |
       | JDBC_SKIP_RECOVERY           | false                                    |
       | TX_DATABASE_PREFIX_MAPPING   | TEST                                     |
       | TEST_DRIVER                  | unknown                                  |
       | TEST_USERNAME                | txnuser                                  |
       | TEST_PASSWORD                | txnpassword                              |
       | TEST_SERVICE_HOST            | 10.1.1.1                                 |
       | TEST_SERVICE_PORT            | 5432                                     |
       | TEST_DATABASE                | txndb                                    |
       | NODE_NAME                    | Test-Store-Node-Name                     |
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-jdbc-store-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-jdbc-store-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain There is not defined variable 'TEST_DATABASE_TYPE' and the PREFIX part of the TX_DATABASE_PREFIX_MAPPING='TEST' does not contain information on database type.

Scenario: Fail to run jdbc recovery when host or url is not specified
    When container is started with command bash
       | variable                     | value                                    |
       | JDBC_SKIP_RECOVERY           | false                                    |
       | TX_DATABASE_PREFIX_MAPPING   | TEST                                     |
       | TEST_USERNAME                | txnuser                                  |
       | TEST_PASSWORD                | txnpassword                              |
       | TEST_SERVICE_PORT            | 5432                                     |
       | TEST_DATABASE                | txndb                                    |
       | NODE_NAME                    | Test-Store-Node-Name                     |
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-jdbc-store-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-jdbc-store-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain ERROR The image startup could fail. For disabling transaction database scaledown processing do NOT use property TX_DATABASE_PREFIX_MAPPING.