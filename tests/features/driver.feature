@jboss-eap-7-tech-preview
Feature: EAP Openshift drivers

  Scenario: check h2 driver only
    # The base image comes with h2 driver only.
    When container is ready
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value h2 on XPath //*[local-name()='driver']/@name

  Scenario: check postgresql driver
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-postgres with env and true
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='drivers']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value postgresql on XPath //*[local-name()='drivers']/*[local-name()='driver']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.jdbc on XPath //*[local-name()='drivers']/*[local-name()='driver']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.xa.PGXADataSource on XPath //*[local-name()='drivers']/*[local-name()='driver']/*[local-name()='xa-datasource-class']

  Scenario: check mysql driver
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-prov-mysql with env and true
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='drivers']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mysql on XPath //*[local-name()='drivers']/*[local-name()='driver']/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc on XPath //*[local-name()='drivers']/*[local-name()='driver']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.cj.jdbc.MysqlXADataSource on XPath //*[local-name()='drivers']/*[local-name()='driver']/*[local-name()='xa-datasource-class']

  Scenario: check postgresql and mysql drivers
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-prov-mysql-postgres with env and true
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='drivers']/*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.jdbc on XPath //*[local-name()='drivers']/*[local-name()='driver' and @name='postgresql']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.postgresql.xa.PGXADataSource on XPath //*[local-name()='drivers']/*[local-name()='driver' and @name='postgresql']/*[local-name()='xa-datasource-class']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.jdbc on XPath //*[local-name()='drivers']/*[local-name()='driver' and @name='mysql']/@module
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value com.mysql.cj.jdbc.MysqlXADataSource on XPath //*[local-name()='drivers']/*[local-name()='driver' and @name='mysql']/*[local-name()='xa-datasource-class']
