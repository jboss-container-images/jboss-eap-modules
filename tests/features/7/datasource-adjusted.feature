@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift datasources with adjusted base config

# This does tests where we modify the base configuration before we try to start the container

Scenario: Adding ExampleDS when already in config gives an error
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
    And file /tmp/boot.log should contain ERROR "You have set environment variables to configure the default datasource 'ExampleDS'. However, your base configuration already contains a datasource with that name."

Scenario: Can add an xa datasource when datasources already exist and the names don't clash
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
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

Scenario: Cannot add an xa datasource when an xa datasource already exists with a clashing name
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=B                 |
       | B_DATABASE                | kitchensink                  |
       | B_USERNAME                | marek                        |
       | B_PASSWORD                | hardtoguess                  |
       | B_TX_ISOLATION            | TRANSACTION_REPEATABLE_READ  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain ERROR "You have set environment variables to configure the datasource 'test_mysql-B'. However, your base configuration already contains a datasource with that name."

Scenario: Cannot add an xa datasource when a non-xa datasource already exists with a clashing name
    When container is started with command bash
       | variable                      | value            |
       | DB_SERVICE_PREFIX_MAPPING     | test-mysql=A     |
       | A_DATABASE                    | kitchensink      |
       | A_USERNAME                    | marek            |
       | A_PASSWORD                    | hardtoguess      |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1         |
       | TEST_MYSQL_SERVICE_PORT       | 3306             |
       | JDBC_SKIP_RECOVERY            | true             |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain ERROR "You have set environment variables to configure the datasource 'test_mysql-A'. However, your base configuration already contains a datasource with that name."

Scenario: Cannot add a non-xa datasource when a non-xa datasource already exists with a clashing name
    When container is started with command bash
       | variable                      | value            |
       | DB_SERVICE_PREFIX_MAPPING     | test-mysql=A     |
       | A_DATABASE                    | kitchensink      |
       | A_USERNAME                    | marek            |
       | A_PASSWORD                    | hardtoguess      |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1         |
       | TEST_MYSQL_SERVICE_PORT       | 3306             |
       | A_NONXA                       | true             |
       | JDBC_SKIP_RECOVERY            | true             |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain ERROR "You have set environment variables to configure the datasource 'test_mysql-A'. However, your base configuration already contains a datasource with that name."

Scenario: Cannot add a non-xa datasource when an xa datasource already exists with a clashing name
    When container is started with command bash
       | variable                      | value            |
       | DB_SERVICE_PREFIX_MAPPING     | test-mysql=B     |
       | B_DATABASE                    | kitchensink      |
       | B_USERNAME                    | marek            |
       | B_PASSWORD                    | hardtoguess      |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1         |
       | TEST_MYSQL_SERVICE_PORT       | 3306             |
       | B_NONXA                       | true             |
       | JDBC_SKIP_RECOVERY            | true             |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain ERROR "You have set environment variables to configure the datasource 'test_mysql-B'. However, your base configuration already contains a datasource with that name."