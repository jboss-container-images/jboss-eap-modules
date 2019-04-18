@jboss-eap-7
@wip
Feature: Openshift EAP Microprofile-tracing Tests

  Scenario: Test microprofile-tracing is enabled
    When container is started with env
      | variable                         | value                                                        |
      | WILDFLY_TRACING_ENABLED          | true                                                         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.wildfly.extension.microprofile.opentracing-smallrye on XPath //*[local-name()='extension'][@module='org.wildfly.extension.microprofile.opentracing-smallrye']/@module


  #@TODO: this doesn't work as expected, check problem with XPATH, independently of WILDFLY_TRACING_ENABLED value, it always passes
  Scenario: Test microprofile-tracing is disabled
    When container is started with env
      | variable                         | value                                                        |
      | WILDFLY_TRACING_ENABLED          | true                                                        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='extension'][@module='org.wildfly.extension.microprofile.opentracing-smallrye']/@module