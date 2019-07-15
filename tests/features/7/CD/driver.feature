@jboss-eap-7-tech-preview/eap-cd-openshift
Feature: EAP Openshift drivers

  Scenario: check no drivers
    # The base image comes with no drivers
    When container is ready
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='driver']


  Scenario: check postgresql driver
    Given s2i build https://github.com/openshift/openshift-jee-sample
        | variable                                 | value              |
        | GALLEON_PROVISION_DEFAULT_CONFIG_LAYERS  | postgresql-driver  |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='driver']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.jdbc on XPath //*[local-name()='driver']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.xa.PGXADataSource on XPath //*[local-name()='driver']/*[local-name()='xa-datasource-class']

  Scenario: check mysql driver
    Given s2i build https://github.com/openshift/openshift-jee-sample
        | variable                                 | value              |
        | GALLEON_PROVISION_DEFAULT_CONFIG_LAYERS  | mysql-driver       |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='driver']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc on XPath //*[local-name()='driver']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc.jdbc2.optional.MysqlXADataSource on XPath //*[local-name()='driver']/*[local-name()='xa-datasource-class']

  Scenario: check postgresql and mysql drivers
    Given s2i build https://github.com/openshift/openshift-jee-sample
        | variable                                 | value                           |
        | GALLEON_PROVISION_DEFAULT_CONFIG_LAYERS  | postgresql-driver,mysql-driver  |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.jdbc on XPath //*[local-name()='driver' and @name='postgresql']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.xa.PGXADataSource on XPath //*[local-name()='driver' and @name='postgresql']/*[local-name()='xa-datasource-class']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc on XPath //*[local-name()='driver' and @name='mysql']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc.jdbc2.optional.MysqlXADataSource on XPath //*[local-name()='driver' and @name='mysql']/*[local-name()='xa-datasource-class']
