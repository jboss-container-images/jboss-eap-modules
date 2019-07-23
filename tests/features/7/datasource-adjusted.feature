@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift datasources with adjusted base config

  Scenario: ExampleDS already in config is not changed
    #wildfly-cekit-modules has been updated to only add the default ds if ENABLE_GENERATE_DEFAULT_DATASOURCE=true
    When container is started with command bash
       | variable                           | value           |
       | ENABLE_GENERATE_DEFAULT_DATASOURCE | true            |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-example-datasource-with-non-std-jndi-name.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-example-datasource-with-non-std-jndi-name.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS-original on XPath //*[local-name()='datasource']/@jndi-name

Scenario: Can add an xa datasource when datasources already exist and the names don't clash
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MIN_POOL_SIZE        | 1                            |
       | TEST_MAX_POOL_SIZE        | 10                           |
       | TEST_TX_ISOLATION         | TRANSACTION_REPEATABLE_READ  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds

Scenario: Can add a non-xa datasource when datasources already exist and the names don't clash
    When container is started with command bash
       | variable                      | value            |
       | DB_SERVICE_PREFIX_MAPPING     | test-mysql=TEST  |
       | TEST_DATABASE                 | kitchensink      |
       | TEST_USERNAME                 | marek            |
       | TEST_PASSWORD                 | hardtoguess      |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1         |
       | TEST_MYSQL_SERVICE_PORT       | 3306             |
       | TEST_NONXA                    | true             |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds

