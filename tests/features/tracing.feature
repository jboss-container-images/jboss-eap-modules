# CLOUD-3949
@ignore 
@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift open-tracing tests

  Scenario: No tracing
    When container is started with env
       | variable                    | value             |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]

  Scenario: Remove non existing tracing
    When container is started with env
       | variable                    | value             |
       | WILDFLY_TRACING_ENABLED     | false             |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]

  Scenario: Enable tracing
    When container is started with env
       | variable                    | value             |
       | WILDFLY_TRACING_ENABLED     | true              |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
  
  Scenario: Observability, open-tracing should already be there, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value             |
    | GALLEON_PROVISION_LAYERS    | cloud-server     |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
  
  Scenario: Enable tracing, no effect, Observability, open-tracing should already be there, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value             |
    | GALLEON_PROVISION_LAYERS    | cloud-server     |
    | WILDFLY_TRACING_ENABLED     | true              |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
  
  Scenario: Disable tracing, open-tracing should be removed, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value             |
    | GALLEON_PROVISION_LAYERS    | cloud-server     |
    | WILDFLY_TRACING_ENABLED     | false              |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
 
  Scenario: No tracing extension, should fail, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
    | variable                    | value             |
    | GALLEON_PROVISION_LAYERS    | web-server        |
    | WILDFLY_TRACING_ENABLED     | true              |
    Then container log should contain WFLYCTL0310: Extension module org.wildfly.extension.microprofile.opentracing-smallrye not found