@jboss-eap-7-tech-preview/eap-cd-openshift
Feature: Check logging configuration

  Scenario: Check that EAP CD logs are json formatted
    When container is started with env
       | variable                    | value             |
       | ENABLE_JSON_LOGGING         | true              |
    Then container log should contain "message":"WFLYSRV0025:
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OPENSHIFT on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Check that EAP7 logs are normally formatted
    When container is started with env
       | variable                    | value              |
       | ENABLE_JSON_LOGGING         | false              |
    Then container log should contain WFLYSRV0025:
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value COLOR-PATTERN on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Check that EAP CD logs are json formatted, galleon s2i
   Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value             |
    | GALLEON_PROVISION_LAYERS    | jaxrs-server      |
    | ENABLE_JSON_LOGGING         | true              |
    Then container log should contain "message":"WFLYSRV0025:
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value OPENSHIFT on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Check that EAP7 logs are normally formatted, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value         |
    | GALLEON_PROVISION_LAYERS    | jaxrs-server  |
    | ENABLE_JSON_LOGGING         | false         |
    Then container log should contain WFLYSRV0025:
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value COLOR-PATTERN on XPath //*[local-name()='console-handler']/*[local-name()='formatter']/*[local-name()='named-formatter']/@name

  Scenario: Add logging category, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                   | value            |
       | GALLEON_PROVISION_LAYERS   | core-server      |
       | LOGGER_CATEGORIES          | org.foo.bar:TRACE  |
    Then container log should contain WFLYSRV0025:
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='logger'][@category="org.foo.bar"]
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRACE on XPath //*[local-name()='logger'][@category="org.foo.bar"]/*[local-name()='level']/@name

  Scenario: Logging, No logging should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                   | value         |
       | GALLEON_PROVISION_LAYERS   | jaxrs         |
       | LOGGER_CATEGORIES          | org.foo.bar:ALL     |
    Then container log should contain You have set LOGGER_CATEGORIES to configure a logger. Fix your configuration to contain the logging subsystem for this to happen.
