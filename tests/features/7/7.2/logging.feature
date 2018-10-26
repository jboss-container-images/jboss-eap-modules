@jboss-eap-7/eap72-openshift
Feature: Check logging configuration

  Scenario: Check that EAP CD logs are json formatted
    When container is started with env
       | variable                    | value             |
       | ENABLE_JSON_LOGGING         | true              |
    Then container log should contain "message":"WFLYSRV0025: JBoss EAP 7.2.0.GA
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OPENSHIFT on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Check that EAP7 logs are normally formatted
    When container is started with env
       | variable                    | value              |
       | ENABLE_JSON_LOGGING         | false              |
    Then container log should contain WFLYSRV0025: JBoss EAP 7.2.0.GA
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value COLOR-PATTERN on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name
