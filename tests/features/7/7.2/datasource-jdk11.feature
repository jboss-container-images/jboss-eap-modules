@jboss-eap-7/eap72-openjdk11-ubi8-openshift
@wip
Feature: EAP Openshift datasources

  Scenario: check mysql datasource
    When container is started with env
       | variable                  | value            |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST |
       | TEST_DATABASE             | kitchensink      |
       | TEST_USERNAME             | marek            |
       | TEST_PASSWORD             | hardtoguess      |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1         |
       | TEST_MYSQL_SERVICE_PORT   | 3306             |
       | TIMER_SERVICE_DATA_STORE  | test-mysql       |
       | JDBC_SKIP_RECOVERY        | true             |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  Scenario: check mysql datasource with advanced settings
    When container is started with env
       | variable                  | value                       |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST             |
       | TEST_DATABASE             | kitchensink                 |
       | TEST_USERNAME             | marek                       |
       | TEST_PASSWORD             | hardtoguess                 |
       | TEST_MIN_POOL_SIZE        | 1                           |
       | TEST_MAX_POOL_SIZE        | 10                          |
       | TEST_TX_ISOLATION         | TRANSACTION_REPEATABLE_READ |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                    |
       | TEST_MYSQL_SERVICE_PORT   | 3306                        |
       | JDBC_SKIP_RECOVERY        | true                        |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  Scenario: check mysql datasource with partial advanced settings
    When container is started with env
       | variable                  | value                       |
       | DB_SERVICE_PREFIX_MAPPING | test-mysql=TEST             |
       | TEST_DATABASE             | kitchensink                 |
       | TEST_USERNAME             | marek                       |
       | TEST_PASSWORD             | hardtoguess                 |
       | TEST_MAX_POOL_SIZE        | 10                          |
       | TEST_MYSQL_SERVICE_HOST   | 10.1.1.1                    |
       | TEST_MYSQL_SERVICE_PORT   | 3306                        |
       | JDBC_SKIP_RECOVERY        | true                        |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  # https://issues.jboss.org/browse/CLOUD-508
  Scenario: check default for timer service datastore
    When container is ready
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value default-file-store on XPath //*[local-name()='file-data-store']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='timer-service']/*[local-name()='data-stores']

  Scenario: check postgresql datasource
    When container is started with env
       | variable                      | value                      |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST       |
       | TEST_DATABASE                 | kitchensink                |
       | TEST_USERNAME                 | marek                      |
       | TEST_PASSWORD                 | hardtoguess                |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                   |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                       |
       | TIMER_SERVICE_DATA_STORE      | test-postgresql            |
       | JDBC_SKIP_RECOVERY            | true                       |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  Scenario: check postgresql datasource with advanced settings
    When container is started with env
       | variable                      | value                       |
       | DB_SERVICE_PREFIX_MAPPING     | test-postgresql=TEST        |
       | TEST_DATABASE                 | kitchensink                 |
       | TEST_USERNAME                 | marek                       |
       | TEST_PASSWORD                 | hardtoguess                 |
       | TEST_MIN_POOL_SIZE            | 1                           |
       | TEST_MAX_POOL_SIZE            | 10                          |
       | TEST_TX_ISOLATION             | TRANSACTION_REPEATABLE_READ |
       | TEST_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                    |
       | TEST_POSTGRESQL_SERVICE_PORT  | 5432                        |
       | JDBC_SKIP_RECOVERY            | true                        |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

  Scenario: Test database type is extracted properly even when name contains a dash (e.g. "eap-app")
    When container is started with env
      | variable                         | value                         |
      | DB_SERVICE_PREFIX_MAPPING        | eap-app-postgresql=TEST       |
      | TEST_DATABASE                    | kitchensink                   |
      | TEST_USERNAME                    | marek                         |
      | TEST_PASSWORD                    | hardtoguess                   |
      | EAP_APP_POSTGRESQL_SERVICE_HOST  | 10.1.1.1                      |
      | EAP_APP_POSTGRESQL_SERVICE_PORT  | 5432                          |
      | JDBC_SKIP_RECOVERY               | true                          |
    Then container log should contain WARN DRIVER not set for datasource TEST. Datasource will not be configured.

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
    Then container log should contain WARN DRIVER not set for datasource TEST_POSTGRESQL. Datasource will not be configured.
      and container log should contain WARN DRIVER not set for datasource TEST_MYSQL. Datasource will not be configured.

  Scenario: check that exampleDS is generated by default (CLOUD-7)
    When container is started with env
       | variable                      | value                                                  |
       | TIMER_SERVICE_DATA_STORE      | ExampleDS            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS_ds on XPath //*[local-name()='database-data-store']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS on XPath //*[local-name()='database-data-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value hsql on XPath //*[local-name()='database-data-store']/@database
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ExampleDS_part on XPath //*[local-name()='database-data-store']/@partition

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

  Scenario: Test postgresql xa datasource extension with hyphenated node name
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
       | TEST_NONXA                     | false                                  |
       | TEST_JTA                       | true                                   |
       | JDBC_STORE_JNDI_NAME           | java:/jboss/datasources/testds         |
       | NODE_NAME                      | Test-Store-Node-Name                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='xa-datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 5432 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="PortNumber"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pgdb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='jdbc-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property']

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 10.1.1.1 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="ServerName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 3306 on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="Port"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="DatabaseName"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='xa-datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property']

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/kitchensink on XPath //*[local-name()='datasource']/*[local-name()='connection-url']

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/kitchensink on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property']

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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@samplehost:1521:oracledb on XPath //*[local-name()='xa-datasource']/*[local-name()='xa-datasource-property'][@name="URL"]
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@samplehost:1521:oracledb on XPath //*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value oracle on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']

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
