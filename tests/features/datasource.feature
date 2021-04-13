@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift datasources

  Scenario: check mysql datasource
    When container is started with env
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # Check defaults in other affected subsystems
    # We will not do these extra checks for the everywhere (just once for each kind of ds), but will have other tests where we set them.
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='file-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value timer-service-data on XPath //*[local-name()='file-data-store']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jboss.server.data.dir on XPath //*[local-name()='file-data-store']/@relative-to
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value in-memory on XPath //*[local-name()='default-job-repository']/@name
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check mysql datasource with advanced settings
    When container is started with env
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_REPEATABLE_READ on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']

  Scenario: check mysql datasource with partial advanced settings
    When container is started with env
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MAX_POOL_SIZE        | 10                           |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']

  # https://issues.jboss.org/browse/CLOUD-508
  Scenario: check default for timer service datastore
    When container is ready
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='file-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='timer-service']/*[local-name()='data-stores'] and wait 30 seconds

  Scenario: check postgresql datasource
    When container is started with env
       | variable                  | value                            |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST         |
       | TEST_DATABASE                 | kitchensink                  |
       | TEST_USERNAME                 | marek                        |
       | TEST_PASSWORD                 | hardtoguess                  |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                     |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                         |
       | JDBC_SKIP_RECOVERY            | true                         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # Check defaults in other affected subsystems
    # We will not do these extra checks for the everywhere (just once for each kind of ds), but will have other tests where we set them.
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='file-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value timer-service-data on XPath //*[local-name()='file-data-store']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jboss.server.data.dir on XPath //*[local-name()='file-data-store']/@relative-to
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value in-memory on XPath //*[local-name()='default-job-repository']/@name
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check postgresql datasource with advanced settings
    When container is started with env
       | variable                  | value                            |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST         |
       | TEST_DATABASE                 | kitchensink                  |
       | TEST_USERNAME                 | marek                        |
       | TEST_PASSWORD                 | hardtoguess                  |
       | TEST_MIN_POOL_SIZE            | 1                            |
       | TEST_MAX_POOL_SIZE            | 10                           |
       | TEST_TX_ISOLATION             | TRANSACTION_REPEATABLE_READ  |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                     |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                         |
       | JDBC_SKIP_RECOVERY            | true                         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='min-pool-size']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-pool']/*[local-name()='max-pool-size']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_REPEATABLE_READ on XPath //*[local-name()='xa-datasource']/*[local-name()='transaction-isolation']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']

  Scenario: Test database type is extracted properly even when name contains a dash (e.g. "eap-app")
    When container is started with env
      | variable                  | value                            |
      | DB_SERVICE_PREFIX_MAPPING        | eap-app-postgresql=TEST   |
      | TEST_DATABASE                    | kitchensink               |
      | TEST_USERNAME                    | marek                     |
      | TEST_PASSWORD                    | hardtoguess               |
      | EAP_APP_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                  |
      | EAP_APP_POSTGRESQL_SERVICE_PORT  | 5432                      |
      | JDBC_SKIP_RECOVERY               | true                      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/eap_app_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value eap_app_postgresql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']

  Scenario: check mysql and postgresql datasource
    When container is started with env
       | variable                      | value                                                  |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST_POSTGRESQL,test-mysql=TEST_MYSQL  |
       | TEST_MYSQL_DATABASE           | kitchensink-m                                          |
       | TEST_MYSQL_USERNAME           | marek-m                                                |
       | TEST_MYSQL_PASSWORD           | hardtoguess-m                                          |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1                                               |
       | TEST_MYSQL_SERVICE_PORT       | 3306                                                   |
       | TEST_POSTGRESQL_DATABASE      | kitchensink-p                                          |
       | TEST_POSTGRESQL_USERNAME      | marek-p                                                |
       | TEST_POSTGRESQL_PASSWORD      | hardtoguess-p                                          |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.2                                               |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                                                   |
       | JDBC_SKIP_RECOVERY            | true                                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink-p on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek-p on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess-p on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink-m on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek-m on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess-m on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # Check defaults in other affected subsystems
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='file-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value timer-service-data on XPath //*[local-name()='file-data-store']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jboss.server.data.dir on XPath //*[local-name()='file-data-store']/@relative-to
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value in-memory on XPath //*[local-name()='default-job-repository']/@name
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should contain WARN The default datasource for the ee subsystem has been guessed to be java:jboss/datasources/test_postgresql. Specify this using EE_DEFAULT_DATASOURCE

  Scenario: check that exampleDS is generated by default if enabled (CLOUD-7)
    #wildfly-cekit-modules has been updated to only add this if ENABLE_GENERATE_DEFAULT_DATASOURCE=true
    When container is started with env
       | variable                      | value                |
       | TIMER_SERVICE_DATA_STORE      | ExampleDS            |
       | ENABLE_GENERATE_DEFAULT_DATASOURCE | true            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hsql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS_part on XPath //*[local-name()='database-data-store']/@partition
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check that exampleDS is not generated by default
    #wildfly-cekit-modules has been updated to only add this if ENABLE_GENERATE_DEFAULT_DATASOURCE=true
    When container is started with env
       | variable                      | value                |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds

  Scenario: Test warning no username is provided
    When container is started with env
       | variable                      | value                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST       |
       | TEST_DATABASE                 | kitchensink                |
       | TEST_PASSWORD                 | hardtoguess                |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                   |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                       |
    Then container log should contain WARN The postgresql datasource for TEST service WILL NOT be configured.
    And container log should contain TEST_PASSWORD: hardtoguess

  Scenario: Test warning on missing database type
    When container is started with env
       | variable                      | value                |
       | DB_SERVICE_PREFIX_MAPPING     | test=TEST            |
       | TEST_DATABASE                 | kitchensink          |
       | TEST_USERNAME                 | marek                |
       | TEST_PASSWORD                 | hardtoguess          |
       | TEST_SERVICE_HOST             | 10.1.1.1             |
       | TEST_SERVICE_PORT             | 5432                 |
    Then container log should contain The mapping does not contain the database type.
    Then container log should contain WARN The datasource for TEST service WILL NOT be configured.

  Scenario: Test warning on missing driver
    When container is started with env
       | variable                       | value                                  |
       | DATASOURCES                    | TEST                                   |
       | TEST_JNDI                      | java:/jboss/datasources/testds         |
       | TEST_USERNAME                  | tombrady                               |
       | TEST_PASSWORD                  | password                               |
       | TEST_SERVICE_HOST              | 10.1.1.1                               |
       | TEST_SERVICE_PORT              | 5432                                   |
       | TEST_DATABASE                  | pgdb                                   |
       | TEST_NONXA                     | false                                  |
       | TEST_JTA                       | true                                   |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  Scenario: Test postgresql non-xa datasource extension
    When container is started with env
       | variable                       | value                                  |
       | DATASOURCES                    | TEST                                   |
       | TEST_JNDI                      | java:/jboss/datasources/testds         |
       | TEST_DRIVER                    | postgresql                             |
       | TEST_USERNAME                  | tombrady                               |
       | TEST_PASSWORD                  | password                               |
       | TEST_SERVICE_HOST              | 10.1.1.1                               |
       | TEST_SERVICE_PORT              | 5432                                   |
       | TEST_DATABASE                  | pgdb                                   |
       | TEST_NONXA                     | true                                   |
       | TEST_JTA                       | false                                  |
       | JDBC_SKIP_RECOVERY             | true                                   |
       | TEST_TX_ISOLATION              | TRANSACTION_REPEATABLE_READ            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_REPEATABLE_READ on XPath //*[local-name()='datasource']/*[local-name()='transaction-isolation']

  Scenario: Test postgresql xa datasource extension w/URL
    When container is started with env
       | variable                        | value                                  |
       | DATASOURCES                     | TEST                                   |
       | TEST_JNDI                       | java:/jboss/datasources/testds         |
       | TEST_DRIVER                     | postgresql                             |
       | TEST_USERNAME                   | tombrady                               |
       | TEST_PASSWORD                   | password                               |
       | TEST_XA_CONNECTION_PROPERTY_URL | jdbc:postgresql://10.1.1.1:5432/pgdb   |
       | TEST_NONXA                      | false                                  |
       | TEST_JTA                        | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'] and wait 30 seconds

  Scenario: Test mysql xa datasource extension
    When container is started with env
       | variable                       | value                                  |
       | DATASOURCES                    | TEST                                   |
       | TEST_JNDI                      | java:/jboss/datasources/testds         |
       | TEST_DRIVER                    | mysql                                  |
       | TEST_USERNAME                  | tombrady                               |
       | TEST_PASSWORD                  | password                               |
       | TEST_SERVICE_HOST              | 10.1.1.1                               |
       | TEST_SERVICE_PORT              | 3306                                   |
       | TEST_DATABASE                  | kitchensink                            |
       | TEST_NONXA                     | false                                  |
       | TEST_JTA                       | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'] and wait 30 seconds

  Scenario: Test mysql non-xa datasource extension
    When container is started with env
       | variable                       | value                                  |
       | DATASOURCES                    | TEST                                   |
       | TEST_JNDI                      | java:/jboss/datasources/testds         |
       | TEST_DRIVER                    | mysql                                  |
       | TEST_USERNAME                  | tombrady                               |
       | TEST_PASSWORD                  | password                               |
       | TEST_SERVICE_HOST              | 10.1.1.1                               |
       | TEST_SERVICE_PORT              | 3306                                   |
       | TEST_DATABASE                  | kitchensink                            |
       | TEST_NONXA                     | true                                   |
       | TEST_JTA                       | false                                  |
       | TEST_TX_ISOLATION              | TRANSACTION_REPEATABLE_READ            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/kitchensink on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_REPEATABLE_READ on XPath //*[local-name()='datasource']/*[local-name()='transaction-isolation']

  Scenario: Test mysql xa datasource extension w/URL
    When container is started with env
       | variable                        | value                                  |
       | DATASOURCES                     | TEST                                   |
       | TEST_JNDI                       | java:/jboss/datasources/testds         |
       | TEST_DRIVER                     | mysql                                  |
       | TEST_USERNAME                   | tombrady                               |
       | TEST_PASSWORD                   | password                               |
       | TEST_XA_CONNECTION_PROPERTY_URL | jdbc:mysql://10.1.1.1:3306/kitchensink |
       | TEST_NONXA                      | false                                  |
       | TEST_JTA                        | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value jdbc:mysql://10.1.1.1:3306/kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'] and wait 30 seconds

  Scenario: Test external xa datasource extension
    When container is started with env
       | variable                          | value                                      |
       | DATASOURCES                       | TEST                                       |
       | TEST_JNDI                         | java:/jboss/datasources/testds             |
       | TEST_DRIVER                       | oracle                                     |
       | TEST_USERNAME                     | tombrady                                   |
       | TEST_PASSWORD                     | password                                   |
       | TEST_XA_CONNECTION_PROPERTY_URL   | jdbc:oracle:thin:@samplehost:1521:oracledb |
       | TEST_NONXA                        | false                                      |
       | TEST_JTA                          | true                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value jdbc:oracle:thin:@samplehost:1521:oracledb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='xa-datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']

  Scenario: Test external non-xa datasource extension
    When container is started with env
       | variable                          | value                                      |
       | DATASOURCES                       | TEST                                       |
       | TEST_JNDI                         | java:/jboss/datasources/testds             |
       | TEST_DRIVER                       | oracle                                     |
       | TEST_USERNAME                     | tombrady                                   |
       | TEST_PASSWORD                     | password                                   |
       | TEST_SERVICE_PORT                 | 1521                                       |
       | TEST_SERVICE_HOST                 | 10.1.1.1                                   |
       | TEST_DATABASE                     | oracledb                                   |
       | TEST_URL                          | jdbc:oracle:thin:@samplehost:1521:oracledb |
       | TEST_NONXA                        | true                                       |
       | TEST_JTA                          | false                                      |
       | TEST_TX_ISOLATION                 | TRANSACTION_REPEATABLE_READ                |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@samplehost:1521:oracledb on XPath //*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRANSACTION_REPEATABLE_READ on XPath //*[local-name()='datasource']/*[local-name()='transaction-isolation']

  Scenario: Test warning no xa-connection-properties for external xa db
    When container is started with env
       | variable                       | value                                  |
       | DATASOURCES                    | TEST                                   |
       | TEST_JNDI                      | java:/jboss/datasources/testds         |
       | TEST_DRIVER                    | oracle                                 |
       | TEST_USERNAME                  | tombrady                               |
       | TEST_PASSWORD                  | password                               |
       | TEST_SERVICE_HOST              | 10.1.1.1                               |
       | TEST_DATABASE                  | testdb                                 |
       | TEST_SERVICE_PORT              | 5432                                   |
       | TEST_NONXA                     | false                                  |
       | TEST_JTA                       | true                                   |
    Then container log should contain WARN At least one TEST_XA_CONNECTION_PROPERTY_property for datasource TEST is required. Datasource will not be configured.

  Scenario: Test warning no password is provided
    When container is started with env
       | variable                      | value                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST       |
       | TEST_DATABASE                 | kitchensink                |
       | TEST_USERNAME                 | marek                      |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                   |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                       |
    Then container log should contain WARN The postgresql datasource for TEST service WILL NOT be configured.
    And container log should contain TEST_JNDI: java:jboss/datasources/test_postgresql
    And container log should contain TEST_USERNAME: marek

  Scenario: Test warning no database is provided
    When container is started with env
       | variable                      | value                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST       |
       | TEST_USERNAME                 | marek                      |
       | TEST_PASSWORD                 | hardtoguess                |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                   |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                       |
   Then container log should contain WARN Missing configuration for datasource TEST. TEST_POSTGRESQL_SERVICE_HOST, TEST_POSTGRESQL_SERVICE_PORT, and/or TEST_DATABASE is missing. Datasource will not be configured.

  Scenario: Test warning on wrong mapping
    When container is started with env
       | variable                      | value                                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=MAREK,abc-mysql=DB         |
       | MAREK_USERNAME                | marek                                      |
       | MAREK_PASSWORD                | hardtoguess                                |
   Then container log should contain WARN Missing configuration for datasource MAREK. TEST_POSTGRESQL_SERVICE_HOST, TEST_POSTGRESQL_SERVICE_PORT, and/or MAREK_DATABASE is missing. Datasource will not be configured.
   And container log should contain In order to configure mysql datasource for DB service you need to provide following environment variables: DB_USERNAME and DB_PASSWORD.

  Scenario: Test warning for missing postgresql xa properties
    When container is started with env
       | variable                      | value                      |
       | DATASOURCES                   | TEST                       |
       | TEST_USERNAME                 | tombrady                   |
       | TEST_PASSWORD                 | Need6Rings!                |
       | TEST_DRIVER                   | postgresql                 |
    Then container log should contain WARN Missing configuration for XA datasource TEST. Either TEST_XA_CONNECTION_PROPERTY_URL or TEST_XA_CONNECTION_PROPERTY_ServerName, and TEST_XA_CONNECTION_PROPERTY_PortNumber, and TEST_XA_CONNECTION_PROPERTY_DatabaseName is required. Datasource will not be configured.

  Scenario: Test warning for missing mysql xa properties
    When container is started with env
       | variable                      | value                      |
       | DATASOURCES                   | TEST                       |
       | TEST_USERNAME                 | tombrady                   |
       | TEST_PASSWORD                 | Need6Rings!                |
       | TEST_DRIVER                   | mysql                      |
    Then container log should contain WARN Missing configuration for XA datasource TEST. Either TEST_XA_CONNECTION_PROPERTY_URL or TEST_XA_CONNECTION_PROPERTY_ServerName, and TEST_XA_CONNECTION_PROPERTY_Port, and TEST_XA_CONNECTION_PROPERTY_DatabaseName is required. Datasource will not be configured.

  #TODO this one ends up configuring the 'bad' ds so the xml becomes:
  # https://pastebin.com/929S40uN. It seems like the postgresql one should not be there
   Scenario: Test multiple datasources with one incorrect
    When container is started with env
       | variable                      | value                                      |
       | DB_SERVICE_PREFIX_MAPPING     | pg-postgresql=PG,mysql-mysql=MYSQL         |
       | PG_USERNAME                   | pguser                                     |
       | PG_PASSWORD                   | pgpass                                     |
       | PG_POSTGRESQL_SERVICE_HOST    | 10.1.1.1                                   |
       | PG_POSTGRESQL_SERVICE_PORT    | 5432                                       |
       | MYSQL_DATABASE                | kitchensink                                |
       | MYSQL_USERNAME                | mysqluser                                  |
       | MYSQL_PASSWORD                | mysqlpass                                  |
       | MYSQL_MYSQL_SERVICE_HOST      | 10.1.1.1                                   |
       | MYSQL_MYSQL_SERVICE_PORT      | 3306                                       |
       | JDBC_SKIP_RECOVERY            | true                                       |
    Then container log should contain WARN Missing configuration for datasource PG. PG_POSTGRESQL_SERVICE_HOST, PG_POSTGRESQL_SERVICE_PORT, and/or PG_DATABASE is missing. Datasource will not be configured.
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/mysql_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql_mysql-MYSQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysqluser on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysqlpass on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']

  Scenario: Test validation's default configuration
    When container is started with env
      | variable                          | value                                      |
      | DB_SERVICE_PREFIX_MAPPING         | test-postgresql=TEST                       |
      | TEST_DATABASE                     | 007                                        |
      | TEST_USERNAME                     | hello                                      |
      | TEST_PASSWORD                     | world                                      |
      | TEST_POSTGRESQL_SERVICE_HOST      | 10.1.1.1                                   |
      | TEST_POSTGRESQL_SERVICE_PORT      | 5432                                       |
      | TEST_NONXA                        | true                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hello on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value world on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='background-validation']

  Scenario: Test background-validation configuration with default background-validation-milis
    When container is started with env
      | variable                          | value                                      |
      | DB_SERVICE_PREFIX_MAPPING         | test-postgresql=TEST                       |
      | TEST_DATABASE                     | 007                                        |
      | TEST_USERNAME                     | hello                                      |
      | TEST_PASSWORD                     | world                                      |
      | TEST_POSTGRESQL_SERVICE_HOST      | 10.1.1.1                                   |
      | TEST_POSTGRESQL_SERVICE_PORT      | 5432                                       |
      | TEST_NONXA                        | true                                       |
      | TEST_BACKGROUND_VALIDATION        | true                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hello on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value world on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10000 on XPath //*[local-name()='validation']/*[local-name()='background-validation-millis']

  Scenario: Test background-validation configuration with custom background-validation-milis value
    When container is started with env
      | variable                          | value                                      |
      | DB_SERVICE_PREFIX_MAPPING         | test-postgresql=TEST                       |
      | TEST_DATABASE                     | 007                                        |
      | TEST_USERNAME                     | hello                                      |
      | TEST_PASSWORD                     | world                                      |
      | TEST_POSTGRESQL_SERVICE_HOST      | 10.1.1.1                                   |
      | TEST_POSTGRESQL_SERVICE_PORT      | 5432                                       |
      | TEST_NONXA                        | true                                       |
      | TEST_BACKGROUND_VALIDATION        | true                                       |
      | TEST_BACKGROUND_VALIDATION_MILLIS | 3000                                       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='datasource']/@jndi-name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hello on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value world on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='background-validation']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3000 on XPath //*[local-name()='validation']/*[local-name()='background-validation-millis']

  Scenario: Test invalid prefix mapping CLOUD-1743
    When container is started with env
      | variable                          | value                                      |
      | DB_SERVICE_PREFIX_MAPPING         | test-microsoftsql=TEST                     |
      | TX_SERVICE_PREFIX_MAPPING         | test-microsoftsql=TEST                     |
      | TEST_JNDI                         | java:/jboss/datasources/testdb             |
      | TEST_DATABASE                     | 007                                        |
      | TEST_USERNAME                     | hello                                      |
      | TEST_PASSWORD                     | world                                      |
     Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.
     And container log should not contain sed -e expression #1

  @jboss-eap-7
  Scenario: CLOUD-2068, test timer datasource refresh-interval
    When container is started with env
      | variable                                  | value                                  |
      | DATASOURCES                               | TEST                                   |
      | TEST_JNDI                                 | java:/jboss/datasources/testds         |
      | TEST_DRIVER                               | oracle                                 |
      | TEST_USERNAME                             | tombrady                               |
      | TEST_PASSWORD                             | password                               |
      | TEST_URL                                  | jdbc:oracle:thin:@10.1.1.1:1521:testdb |
      | TEST_NONXA                                | true                                   |
      | TEST_JTA                                  | true                                   |
      | TIMER_SERVICE_DATA_STORE                  | TEST                                   |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 60000                                  |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:testdb on XPath //*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 60000 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: CLOUD-2068, test timer datasource refresh-interval
    When container is started with env
      | variable                 | value                                  |
      | DATASOURCES              | TEST                                   |
      | TEST_JNDI                | java:/jboss/datasources/testds         |
      | TEST_DRIVER              | oracle                                 |
      | TEST_USERNAME            | tombrady                               |
      | TEST_PASSWORD            | password                               |
      | TEST_URL                 | jdbc:oracle:thin:@10.1.1.1:1521:testdb |
      | TEST_NONXA               | true                                   |
      | TEST_JTA                 | true                                   |
      | TIMER_SERVICE_DATA_STORE | TEST                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:testdb on XPath //*[local-name()='connection-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test-TEST_part on XPath //*[local-name()='database-data-store']/@partition
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value -1 on XPath //*[local-name()='database-data-store']/@refresh-interval

  Scenario: Test background-validation configuration with custom background-validation-milis value
    When container is started with env
      | variable                                  | value                |
      | DB_SERVICE_PREFIX_MAPPING                 | test-postgresql=TEST |
      | TEST_DATABASE                             | 007                  |
      | TEST_USERNAME                             | hello                |
      | TEST_PASSWORD                             | world                |
      | TEST_POSTGRESQL_SERVICE_HOST              | 10.1.1.1             |
      | TEST_POSTGRESQL_SERVICE_PORT              | 5432                 |
      | TEST_NONXA                                | true                 |
      | TEST_BACKGROUND_VALIDATION                | true                 |
      | TEST_BACKGROUND_VALIDATION_MILLIS         | 3000                 |
      | TIMER_SERVICE_DATA_STORE_REFRESH_INTERVAL | 60000                |
      | TIMER_SERVICE_DATA_STORE                  | test-postgresql      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='datasource']/@jndi-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hello on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value world on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='validation']/*[local-name()='validate-on-match']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='validation']/*[local-name()='background-validation']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3000 on XPath //*[local-name()='validation']/*[local-name()='background-validation-millis']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 60000 on XPath //*[local-name()='database-data-store']/@refresh-interval

 Scenario: check mysql datasource with specified DEFAULT_JOB_REPOSITORY and TIMER_SERVICE
    # Tests settings which override the defaults we checked in the 'check mysql datasource' scenario
    When container is started with env
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
       | DEFAULT_JOB_REPOSITORY    | test-mysql                   |
       | TIMER_SERVICE_DATA_STORE  | test-mysql                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    # Skip a lot of the checks done in 'check mysql datasource' anyway
    # Now for what we are after....
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='default-job-repository']/@name
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_ds on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_part on XPath //*[local-name()='database-data-store']/@partition

  Scenario: check postgresql datasource with specified DEFAULT_JOB_REPOSITORY and TIMER_SERVICE
    # Tests settings which override the defaults we checked in the 'check posgresql datasource' scenario
    When container is started with env
       | variable                  | value                            |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST         |
       | TEST_DATABASE                 | kitchensink                  |
       | TEST_USERNAME                 | marek                        |
       | TEST_PASSWORD                 | hardtoguess                  |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                     |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                         |
       | JDBC_SKIP_RECOVERY            | true                         |
       | DEFAULT_JOB_REPOSITORY        | test-postgresql              |
       | TIMER_SERVICE_DATA_STORE      | test-postgresql              |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    # Skip a lot of the checks done in 'check postgresql datasource' anyway
    # Now for what we are after....
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST on XPath //*[local-name()='default-job-repository']/@name
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_ds on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_part on XPath //*[local-name()='database-data-store']/@partition

  Scenario: check mysql and postgresql datasource with specified DEFAULT_JOB_REPOSITORY, TIMER_SERVICE and EE_DEFAULT_DS_JNDI_NAME set to first ds
    When container is started with env
       | variable                  | value                                                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST_POSTGRESQL,test-mysql=TEST_MYSQL  |
       | TEST_MYSQL_DATABASE           | kitchensink-m                                          |
       | TEST_MYSQL_USERNAME           | marek-m                                                |
       | TEST_MYSQL_PASSWORD           | hardtoguess-m                                          |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1                                               |
       | TEST_MYSQL_SERVICE_PORT       | 3306                                                   |
       | TEST_POSTGRESQL_DATABASE      | kitchensink-p                                          |
       | TEST_POSTGRESQL_USERNAME      | marek-p                                                |
       | TEST_POSTGRESQL_PASSWORD      | hardtoguess-p                                          |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.2                                               |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                                                   |
       | JDBC_SKIP_RECOVERY            | true                                                   |
       | DEFAULT_JOB_REPOSITORY        | test-postgresql                                        |
       | TIMER_SERVICE_DATA_STORE      | test-postgresql                                        |
       | EE_DEFAULT_DATASOURCE         | test-postgresql                                        |
    # We test a this in more detail in 'check mysql and postgresql datasource'. Just a quick sanity check here
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL on XPath //*[local-name()='xa-datasource']/@pool-name
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL on XPath //*[local-name()='default-job-repository']/@name
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL_ds on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL_part on XPath //*[local-name()='database-data-store']/@partition
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check mysql and postgresql datasource with specified DEFAULT_JOB_REPOSITORY, TIMER_SERVICE and EE_DEFAULT_DS_JNDI_NAME set to second ds
    When container is started with env
       | variable                  | value                                                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST_POSTGRESQL,test-mysql=TEST_MYSQL  |
       | TEST_MYSQL_DATABASE           | kitchensink-m                                          |
       | TEST_MYSQL_USERNAME           | marek-m                                                |
       | TEST_MYSQL_PASSWORD           | hardtoguess-m                                          |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1                                               |
       | TEST_MYSQL_SERVICE_PORT       | 3306                                                   |
       | TEST_POSTGRESQL_DATABASE      | kitchensink-p                                          |
       | TEST_POSTGRESQL_USERNAME      | marek-p                                                |
       | TEST_POSTGRESQL_PASSWORD      | hardtoguess-p                                          |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.2                                               |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                                                   |
       | JDBC_SKIP_RECOVERY            | true                                                   |
       | DEFAULT_JOB_REPOSITORY        | test-mysql                                             |
       | TIMER_SERVICE_DATA_STORE      | test-mysql                                             |
       | EE_DEFAULT_DATASOURCE         | test-mysql                                             |
    # We test a this in more detail in 'check mysql and postgresql datasource'. Just a quick sanity check here
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL on XPath //*[local-name()='xa-datasource']/@pool-name
    # Default job repository
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL on XPath //*[local-name()='default-job-repository']/@name
    # Timer service
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL_ds on XPath //*[local-name()='timer-service']/@default-data-store
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL_part on XPath //*[local-name()='database-data-store']/@partition
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check datasource with a DEFAULT_JOB_REPOSITORY which does not match any added datasources
	    # Tests settings which override the defaults we checked in the 'check mysql datasource' scenario
	    When container is started with env
	       | variable                  | value                        |
	       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
	       | TEST_DATABASE             | kitchensink                  |
	       | TEST_USERNAME             | marek                        |
	       | TEST_PASSWORD             | hardtoguess                  |
	       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
	       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
	       | JDBC_SKIP_RECOVERY        | true                         |
	       | DEFAULT_JOB_REPOSITORY    | does-not-match-anything      |
	    Then container log should contain ERROR The list of configured datasources does not contain a datasource matching the default job repository datasource specified with DEFAULT_JOB_REPOSITORY='does-not-match-anything'.

	  Scenario: check datasource with a TIMER_SERVICE_DATA_STORE which does not match any added datasources
	    # Tests settings which override the defaults we checked in the 'check mysql datasource' scenario
	    When container is started with env
	       | variable                  | value                        |
	       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
	       | TEST_DATABASE             | kitchensink                  |
	       | TEST_USERNAME             | marek                        |
	       | TEST_PASSWORD             | hardtoguess                  |
	       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
	       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
	       | JDBC_SKIP_RECOVERY        | true                         |
	       | TIMER_SERVICE_DATA_STORE  | does-not-match-anything      |
	    Then container log should contain ERROR The list of configured datasources does not contain a datasource matching the timer-service datastore datasource specified with TIMER_SERVICE_DATA_STORE='does-not-match-anything'.

	  Scenario: check datasource with a EE_DEFAULT_DATASOURCE which does not match any added datasources
	    # Tests settings which override the defaults we checked in the 'check mysql datasource' scenario
	    When container is started with env
	       | variable                  | value                        |
	       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
	       | TEST_DATABASE             | kitchensink                  |
	       | TEST_USERNAME             | marek                        |
	       | TEST_PASSWORD             | hardtoguess                  |
	       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
	       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
	       | JDBC_SKIP_RECOVERY        | true                         |
	       | EE_DEFAULT_DATASOURCE     | does-not-match-anything      |
	    Then container log should contain ERROR The list of configured datasources does not contain a datasource matching the ee default-bindings datasource specified with EE_DEFAULT_DATASOURCE='does-not-match-anything'.

  Scenario: check mysql datasource, galleon s2i
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-prov-mysql with env and true
       | variable                  | value                        |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST              |
       | TEST_DATABASE             | kitchensink                  |
       | TEST_USERNAME             | marek                        |
       | TEST_PASSWORD             | hardtoguess                  |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                     |
       | TEST_MYSQL_SERVICE_PORT   | 3306                         |
       | JDBC_SKIP_RECOVERY        | true                         |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check postgresql datasource, galleon s2i
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-prov-mysql-postgres with env and true
       | variable                  | value                            |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST         |
       | TEST_DATABASE                 | kitchensink                  |
       | TEST_USERNAME                 | marek                        |
       | TEST_PASSWORD                 | hardtoguess                  |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                     |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                         |
       | JDBC_SKIP_RECOVERY            | true                         |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should not contain WARN The default datasource for the ee subsystem has been guessed to be

  Scenario: check mysql and postgresql datasource, galleon s2i
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-prov-mysql-postgres with env and true
       | variable                      | value                                                  |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST_POSTGRESQL,test-mysql=TEST_MYSQL  |
       | TEST_MYSQL_DATABASE           | kitchensink-m                                          |
       | TEST_MYSQL_USERNAME           | marek-m                                                |
       | TEST_MYSQL_PASSWORD           | hardtoguess-m                                          |
       | TEST_MYSQL_SERVICE_HOST       | 10.1.1.1                                               |
       | TEST_MYSQL_SERVICE_PORT       | 3306                                                   |
       | TEST_POSTGRESQL_DATABASE      | kitchensink-p                                          |
       | TEST_POSTGRESQL_USERNAME      | marek-p                                                |
       | TEST_POSTGRESQL_PASSWORD      | hardtoguess-p                                          |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.2                                               |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                                                   |
       | JDBC_SKIP_RECOVERY            | true                                                   |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresql-TEST_POSTGRESQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink-p on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek-p on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess-p on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_mysql on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_mysql-TEST_MYSQL on XPath //*[local-name()='xa-datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 10.1.1.2 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain trimmed value kitchensink-m on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value marek-m on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hardtoguess-m on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    # EE default bindings
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/test_postgresql on XPath //*[local-name()='default-bindings']/@datasource
    And container log should contain WARN The default datasource for the ee subsystem has been guessed to be java:jboss/datasources/test_postgresql. Specify this using EE_DEFAULT_DATASOURCE

  Scenario: check that exampleDS is not generated by default, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                           | value                |
       | GALLEON_PROVISION_LAYERS           | cloud-server   |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds

  Scenario: Create a Data source and its driver at rutime by using environment variables
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-drivers-at-runtime with env and true
       | variable                           | value                                                 |
       | DRIVERS                            | DRVONE,DRVTWO,DRVTHREE                                |
       | DRVONE_DRIVER_NAME                 | drv_one                                               |
       | DRVONE_DRIVER_MODULE               | org.postgresql                                        |
       | DRVONE_DRIVER_CLASS                | org.postgresql.Driver                                 |
       | DRVONE_XA_DATASOURCE_CLASS         | org.postgresql.xa.PGXADataSource                      |
       | DRVTWO_DRIVER_NAME                 | drv_two                                               |
       | DRVTWO_DRIVER_MODULE               | org.postgresql                                        |
       | DRVTWO_XA_DATASOURCE_CLASS         | org.postgresql.xa.PGXADataSource                      |
       | DRVTHREE_DRIVER_NAME               | drv_three                                             |
       | DRVTHREE_DRIVER_MODULE             | org.postgresql                                        |
       | DRVTHREE_DRIVER_CLASS              | org.postgresql.Driver                                 |
       | DB_SERVICE_PREFIX_MAPPING          | dbone-postgresql=DSONE                                |
       | DBONE_POSTGRESQL_SERVICE_HOST      | 10.1.1.1                                              |
       | DBONE_POSTGRESQL_SERVICE_PORT      | 5432                                                  |
       | DSONE_JNDI                         | java:/jboss/datasources/PostgreSQLDS                  |
       | DSONE_DATABASE                     | postgre                                               |
       | DSONE_DRIVER                       | drv_one                                               |
       | DSONE_URL                          | jdbc:postgresql://localhost:5432/postgresdb           |
       | DSONE_NONXA                        | true                                                  |
       | DSONE_USERNAME                     | postgre                                               |
       | DSONE_PASSWORD                     | admin                                                 |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver'][@name='drv_one']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver'][@name='drv_two']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver'][@name='drv_three']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value drv_one on XPath //*[local-name()='datasource']/*[local-name()='driver']