@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift transaction objectstore datasources

  Scenario: Test tx db service mapping w/multiple datasources
    When container is started with env
      | variable                      | value                                      |
      | DB_SERVICE_PREFIX_MAPPING     | pg-postgresql=PG,mysql-mysql=MYSQL         |
      | TX_DATABASE_PREFIX_MAPPING    | mysql-mysql=MYSQL                          |
      | PG_DATABASE                   | kitchensink                                |
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/mysql_mysqlObjectStore on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql_mysqlObjectStorePool on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:mysql://10.1.1.1:3306/kitchensink on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysqluser on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysqlpass on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']

  Scenario: Test tx db service mapping w/multiple datasources and tx is first
    When container is started with env
      | variable                      | value                                      |
      | DB_SERVICE_PREFIX_MAPPING     | pg-postgresql=PG,mysql-mysql=MYSQL         |
      | TX_DATABASE_PREFIX_MAPPING    | pg-postgresql=PG                           |
      | PG_DATABASE                   | kitchensink                                |
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
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/pg_postgresqlObjectStore on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pg_postgresqlObjectStorePool on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/kitchensink on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pguser on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pgpass on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']

    @redhat-sso-7/sso71-openshift
  Scenario: Test postgresql xa datasource extension with TX_DATABASE_PREFIX_MAPPING
    When container is started with env
      | variable                       | value                                  |
      | TX_DATABASE_PREFIX_MAPPING     | TEST_POSTGRESQL                        |
      | TEST_POSTGRESQL_JNDI           | java:/jboss/datasources/testds         |
      | TEST_POSTGRESQL_USERNAME       | tombrady                               |
      | TEST_POSTGRESQL_PASSWORD       | password                               |
      | TEST_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                               |
      | TEST_POSTGRESQL_SERVICE_PORT   | 5432                                   |
      | TEST_POSTGRESQL_DATABASE       | pgdb                                   |
      | NODE_NAME                      | TestStoreNodeName                      |
      | JDBC_SKIP_RECOVERY             | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testdsObjectStore on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresqlObjectStorePool on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix

    @redhat-sso-7/sso71-openshift
  Scenario: Test postgresql xa datasource extension with TX_DATABASE_PREFIX_MAPPING and hyphenated node name
    When container is started with env
      | variable                       | value                                  |
      | TX_DATABASE_PREFIX_MAPPING     | TEST_POSTGRESQL                        |
      | TEST_POSTGRESQL_JNDI           | java:/jboss/datasources/testds         |
      | TEST_POSTGRESQL_USERNAME       | tombrady                               |
      | TEST_POSTGRESQL_PASSWORD       | password                               |
      | TEST_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                               |
      | TEST_POSTGRESQL_SERVICE_PORT   | 5432                                   |
      | TEST_POSTGRESQL_DATABASE       | pgdb                                   |
      | NODE_NAME                      | Test-Store-Node-Name                   |
      | JDBC_SKIP_RECOVERY             | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testdsObjectStore on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='datasource']/@jta
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value test_postgresqlObjectStorePool on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='datasource']/@enabled
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='datasource']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix

  Scenario: Test postgresql xa datasource extension
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
      | TEST_NONXA                     | true                                  |
      | TEST_JTA                       | false                                   |
      | JDBC_STORE_JNDI_NAME           | java:/jboss/datasources/testds         |
      | NODE_NAME                      | TestStoreNodeName                      |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='jdbc-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix

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
      | TEST_NONXA                     | true                                   |
      | TEST_JTA                       | false                                  |
      | JDBC_STORE_JNDI_NAME           | java:/jboss/datasources/testds         |
      | NODE_NAME                      | Test-Store-Node.Name                   |
      | JDBC_SKIP_RECOVERY             | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:postgresql://10.1.1.1:5432/pgdb on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testds on XPath //*[local-name()='jdbc-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix

  Scenario: Adding oracle datasource as jdbc object store
    When container is started with env
      | variable                       | value                                  |
      | TX_DATABASE_PREFIX_MAPPING     | TEST                                   |
      | TEST_JNDI                      | java:/jboss/datasources/testds         |
      | TEST_DRIVER                    | oracle                                 |
      | TEST_USERNAME                  | tombrady                               |
      | TEST_PASSWORD                  | password                               |
      | TEST_URL                       | jdbc:oracle:thin:@10.1.1.1:1521:XE     |
      | TEST_SERVICE_HOST              | 10.1.1.2                               |
      | TEST_SERVICE_PORT              | 1521                                   |
      | TEST_DATABASE                  | XE                                     |
      | TEST_NONXA                     | false                                  |
      | TEST_JTA                       | true                                   |
      | NODE_NAME                      | Test.Store-Node.Name                   |
      | JDBC_SKIP_RECOVERY             | true                                   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testdsObjectStore on XPath //*[local-name()='datasource']/@jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value testObjectStorePool on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jdbc:oracle:thin:@10.1.1.1:1521:XE on XPath //*[local-name()='datasource']/*[local-name()='connection-url']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value tombrady on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='user-name']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value password on XPath //*[local-name()='datasource']/*[local-name()='security']/*[local-name()='password']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:/jboss/datasources/testdsObjectStore on XPath //*[local-name()='jdbc-store']/@datasource-jndi-name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='action']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='communication']/@table-prefix
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value osTestStoreNodeName on XPath //*[local-name()='jdbc-store']/*[local-name()='state']/@table-prefix


  Scenario: Cannot add a transactional log store datasource when an xa datasource already exists with a clashing name
       #Although we use the name 'XA' here this does not refer to the log store we're attempting to add
       #rather the existing datasource that is added by the cli file
       #even the JDBC datastore could be only nonxa datasource the scripts do not permit to name datasource
       #and xa-datasource with the same name
    When container is started with command bash
      | variable                     | value                                    |
      | TX_DATABASE_PREFIX_MAPPING   | XA_POSTGRESQL                            |
      | XA_POSTGRESQL_JNDI           | java:/jboss/datasources/testdsa          |
      | XA_POSTGRESQL_USERNAME       | tombrady                                 |
      | XA_POSTGRESQL_PASSWORD       | password                                 |
      | XA_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                                 |
      | XA_POSTGRESQL_SERVICE_PORT   | 5432                                     |
      | XA_POSTGRESQL_DATABASE       | pgdb                                     |
      | NODE_NAME                    | Test-Store-Node-Name                     |
      | JDBC_SKIP_RECOVERY           | true                                     |
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-jdbc-store-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-jdbc-store-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'xa_postgresqlObjectStorePool'. However, your base configuration already contains a datasource with that name.

  Scenario: Cannot add a transaction log store datasource when a standard datasource already exists with a clashing name
       #Although we use the name 'NONXA' here this does not refer to the log store we're attempting to add
       #rather the existing datasource that is added by the cli file
    When container is started with command bash
      | variable                          | value                                    |
      | TX_DATABASE_PREFIX_MAPPING        | NONXA_POSTGRESQL                         |
      | NONXA_POSTGRESQL_JNDI             | java:/jboss/datasources/testdsa          |
      | NONXA_POSTGRESQL_USERNAME         | tombrady                                 |
      | NONXA_POSTGRESQL_PASSWORD         | password                                 |
      | NONXA_POSTGRESQL_SERVICE_HOST     | 10.1.1.1                                 |
      | NONXA_POSTGRESQL_SERVICE_PORT     | 5432                                     |
      | NONXA_POSTGRESQL_DATABASE         | pgdb                                     |
      | NODE_NAME                         | Test-Store-Node-Name                     |
      | JDBC_SKIP_RECOVERY                | true                                     |
    Then copy features/jboss-eap-modules/scripts/datasource/add-standard-jdbc-store-datasources.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-standard-jdbc-store-datasources.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='xa-datasource'] and wait 30 seconds
    And file /tmp/boot.log should contain You have set environment variables to configure the datasource 'nonxa_postgresqlObjectStorePool'. However, your base configuration already contains a datasource with that name.

  Scenario: Cannot add a transaction log store when a conflicting transaction jdbc logstore already exists
       When container is started with command bash
      | variable                       | value                          |
      | TX_DATABASE_PREFIX_MAPPING     | TEST_POSTGRESQL                |
      | TEST_POSTGRESQL_JNDI           | java:/jboss/datasources/testds |
      | TEST_POSTGRESQL_USERNAME       | kabir                          |
      | TEST_POSTGRESQL_PASSWORD       | password                       |
      | TEST_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                       |
      | TEST_POSTGRESQL_SERVICE_PORT   | 5432                           |
      | TEST_POSTGRESQL_DATABASE       | pgdb                           |
      | NODE_NAME                      | TestStoreNodeName              |
      | JDBC_SKIP_RECOVERY             | true                           |
       Then copy features/jboss-eap-modules/scripts/datasource/transaction-jdbc-log-store.cli to /tmp in container
       And run /opt/eap/bin/jboss-cli.sh --file=/tmp/transaction-jdbc-log-store.cli in container once
       And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
       And file /tmp/boot.log should contain You have set environment variables to configure a jdbc logstore in the transactions subsystem which conflict with the values that already exist in the base configuration. Fix your configuration.

  Scenario: Cannot link an non-xa datasource to the transaction log store when a conflicting transaction jdbc logstore already exists
       #Here is defined only jndi for JDBC store which is to be added but it fails as the cli already added one
       When container is started with command bash
      | variable                       | value                          |
      | DB_SERVICE_PREFIX_MAPPING      | TEST_POSTGRESQL                |
      | TEST_POSTGRESQL_USERNAME       | kabir                          |
      | TEST_POSTGRESQL_PASSWORD       | password                       |
      | TEST_POSTGRESQL_DATABASE       | pgdb                           |
      | TEST_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                       |
      | TEST_POSTGRESQL_SERVICE_PORT   | 5432                           |
      | TEST_POSTGRESQL_NONXA          | true                           |
      | TEST_POSTGRESQL_JTA            | false                          |
      | JDBC_STORE_JNDI_NAME           | java:jboss/datasources/test_postgresql |
      | NODE_NAME                      | TestStoreNodeName              |
      | JDBC_SKIP_RECOVERY             | false                          |
       Then copy features/jboss-eap-modules/scripts/datasource/transaction-jdbc-log-store.cli to /tmp in container
       And run /opt/eap/bin/jboss-cli.sh --file=/tmp/transaction-jdbc-log-store.cli in container once
       And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
       And file /tmp/boot.log should contain You have set environment variables to configure a jdbc logstore in the transactions subsystem which conflict with the values that already exist in the base configuration. Fix your configuration.

  Scenario: JDBC object store creation fails in transactions subsystem while tx mapping identifies postgresql and configure url and creates datasource
      When container is started with command bash
     | variable                       | value                          |
     | TX_DATABASE_PREFIX_MAPPING     | test-postgresql=TEST           |
     | TEST_USERNAME                  | kabir                          |
     | TEST_PASSWORD                  | password                       |
     | TEST_DATABASE                  | pgdb                           |
     | TEST_POSTGRESQL_SERVICE_HOST   | 10.1.1.1                       |
     | TEST_POSTGRESQL_SERVICE_PORT   | 5432                           |
     | TEST_NONXA                     | false                          |
     | NODE_NAME                      | TestStoreNodeName              |
     | JDBC_SKIP_RECOVERY             | true                           |
      Then copy features/jboss-eap-modules/scripts/datasource/transaction-jdbc-log-store-oracle-ds.cli to /tmp in container
      # oracle ds creation has no impact on the postgresql datasource created based on the tx mapping env variable
      And run /opt/eap/bin/jboss-cli.sh --file=/tmp/transaction-jdbc-log-store-oracle-ds.cli in container once
      And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
      And file /tmp/boot.log should contain You have set environment variables to configure a jdbc logstore in the transactions subsystem which conflict with the values that already exist in the base configuration. Fix your configuration.

  Scenario: Oracle datasource for JDBC object store fails as not having url defined
      When container is started with command bash
     | variable                       | value                          |
     | TX_DATABASE_PREFIX_MAPPING     | test-my=TEST                   |
     | TEST_USERNAME                  | kabir                          |
     | TEST_PASSWORD                  | password                       |
     | TEST_DATABASE                  | XE                             |
     | TEST_MY_SERVICE_HOST           | 10.1.1.1                       |
     | TEST_MY_SERVICE_PORT           | 1521                           |
     | TEST_DRIVER                    | oracle                         |
     | TEST_NONXA                     | false                          |
     | NODE_NAME                      | TestStoreNodeName              |
     | JDBC_SKIP_RECOVERY             | true                           |
      Then copy features/jboss-eap-modules/scripts/datasource/transaction-jdbc-log-store-oracle-ds.cli to /tmp in container
      And run /opt/eap/bin/jboss-cli.sh --file=/tmp/transaction-jdbc-log-store-oracle-ds.cli in container once
      And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource'] and wait 30 seconds
      And file /tmp/boot.log should contain WARN The my datasource and JDBC object store for TEST service WILL NOT be configured.