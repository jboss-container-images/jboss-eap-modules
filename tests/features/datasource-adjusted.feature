@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift datasources with adjusted base config

# This does tests where we modify the base configuration before we try to start the container

Scenario: Adding ExampleDS when already in config gives an error
    #wildfly-cekit-modules has been updated to only add the default ds if ENABLE_GENERATE_DEFAULT_DATASOURCE=true
    When container is started with command bash
       | variable                           | value           |
       | ENABLE_GENERATE_DEFAULT_DATASOURCE | true            |
    Then copy features/jboss-eap-modules/scripts/datasource/add-example-datasource-with-non-std-jndi-name.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-example-datasource-with-non-std-jndi-name.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS-original on XPath //*[local-name()='datasource']/@jndi-name
    And file /tmp/boot.log should contain You have set environment variables to configure the default datasource 'ExampleDS'. However, your base configuration already contains a datasource with that name.

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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'test_mysql-B'. However, your base configuration already contains a datasource with that name.

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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'test_mysql-A'. However, your base configuration already contains a datasource with that name.

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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'test_mysql-A'. However, your base configuration already contains a datasource with that name.

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
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'test_mysql-B'. However, your base configuration already contains a datasource with that name.

Scenario: check datasource with default value used for default-job-repository does not give error when no batch-jberet subsystem
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-batch-jberet-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-batch-jberet-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   And file /tmp/boot.log should not contain You have set the DEFAULT_JOB_REPOSITORY environment variables to configure a default-job-repository pointing to

Scenario: check datasource with specified value used for default-job-repository gives error when no batch-jberet subsystem
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | DEFAULT_JOB_REPOSITORY    | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-batch-jberet-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-batch-jberet-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   And file /tmp/boot.log should contain You have set the DEFAULT_JOB_REPOSITORY environment variables to configure a default-job-repository pointing to the 'test-mysql' datasource. Fix your configuration to contain a batch-jberet subsystem for this to happen.

Scenario: check datasource with default value used for timer-service-datastore does not give error when no ejb3 subsystem
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-ejb3-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-ejb3-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   And file /tmp/boot.log should not contain You have set the TIMER_SERVICE_DATA_STORE environment variable which adds a timer-service to the ejb3 subsystem. Fix your configuration to contain an ejb3 subsystem for this to happen.

Scenario: check datasource with specified value used for timer-service-datastore gives error when no ejb3 subsystem
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | TIMER_SERVICE_DATA_STORE  | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-ejb3-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-ejb3-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And file /tmp/boot.log should contain You have set the TIMER_SERVICE_DATA_STORE environment variable which adds a timer-service to the ejb3 subsystem. Fix your configuration to contain an ejb3 subsystem for this to happen.

Scenario: check datasource existing timer-service database-data-store not changed when not specified
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
   Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
   And copy features/jboss-eap-modules/scripts/datasource/add-standard-base-timer-service.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-timer-service.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='database-data-store'] and wait 30 seconds
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-B_ds on XPath //*[local-name()='timer-service']/@default-data-store
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-B_ds on XPath //*[local-name()='database-data-store']/@name
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_b on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_b-TEST_part on XPath //*[local-name()='database-data-store']/@partition

Scenario: check datasource and set timer-service when a database-data-store already exists with a different name
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | TIMER_SERVICE_DATA_STORE  | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
   And copy features/jboss-eap-modules/scripts/datasource/add-standard-base-timer-service.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-timer-service.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='database-data-store'] and wait 30 seconds
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_ds on XPath //*[local-name()='timer-service']/@default-data-store
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-B_ds on XPath //*[local-name()='database-data-store']/@name
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_ds on XPath //*[local-name()='database-data-store']/@name
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='database-data-store'][@name='test_mysql-TEST_ds']/@datasource-jndi-name
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store'][@name='test_mysql-TEST_ds']/@database
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_part on XPath //*[local-name()='database-data-store'][@name='test_mysql-TEST_ds']/@partition

Scenario: check datasource and timer service with a clashing database-data-store name gives error
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | TIMER_SERVICE_DATA_STORE  | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
   And copy features/jboss-eap-modules/scripts/datasource/add-clashing-base-timer-service.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-base-timer-service.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And file /tmp/boot.log should contain You have set environment variables to configure a timer service database-data-store in the ejb3 subsystem which conflict with the values that already exist in the base configuration. Fix your configuration.

Scenario: check guessed EE default-bindings datasource and no EE subsystem does not give error
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-ee-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-ee-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And file /tmp/boot.log should not contain EE_DEFAULT_DATASOURCE was set to

Scenario: check specified EE default-bindings datasource and no EE subsystem gives error
    When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | EE_DEFAULT_DATASOURCE     | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/remove-ee-subsystem.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-ee-subsystem.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And file /tmp/boot.log should contain EE_DEFAULT_DATASOURCE was set to 'test-mysql' but the base configuration contains no ee subsystem. Fix your configuration.

Scenario: check guessed EE default-bindings datasource when there is a conflict in existing values should give a warning
   When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
   Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
   And copy features/jboss-eap-modules/scripts/datasource/add-clashing-base-ee-default-bindings-datasource.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-base-ee-default-bindings-datasource.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And file /tmp/boot.log should contain You have set environment variables to configure the datasource in the default-bindings in the ee subsystem subsystem which conflicts with the value that already exists in the base configuration. The base configuration value will be used. Fix your configuration.

Scenario: check specified EE default-bindings datasource when there is a conflict in existing values should give an error
   When container is started with command bash
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | EE_DEFAULT_DATASOURCE     | test-mysql                   |
   Then copy features/jboss-eap-modules/scripts/datasource/add-standard-base-datasources.cli to /tmp in container
   And copy features/jboss-eap-modules/scripts/datasource/add-clashing-base-ee-default-bindings-datasource.cli to /tmp in container
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-base-datasources.cli in container once
   And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-base-ee-default-bindings-datasource.cli in container once
   And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
   And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
   # Skip a lot of the checks done in 'check mysql datasource' anyway
   # Now for what we are after....
   And file /tmp/boot.log should contain You have set environment variables to configure the datasource in the default-bindings in the ee subsystem subsystem which conflicts with the value that already exists in the base configuration. Fix your configuration.
