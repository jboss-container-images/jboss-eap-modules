@jboss-eap-6
Feature: Check logging configuration

  Scenario: Check that EAP6 logs are json formatted
    When container is started with env
       | variable                    | value             |
       | ENABLE_JSON_LOGGING         | true              |
    Then container log should contain "message":"JBAS015874: JBoss EAP 6
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OPENSHIFT on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Check that EAP6 logs are normally formatted
    When container is started with env
       | variable                    | value              |
       | ENABLE_JSON_LOGGING         | false              |
    Then container log should contain JBAS015874: JBoss EAP 6
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value COLOR-PATTERN on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

