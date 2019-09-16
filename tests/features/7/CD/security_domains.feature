@jboss-eap-7-tech-preview
Feature: EAP Openshift security domains
  Scenario: check Elytron configuration
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env and true using master
       | variable           | value       |
       | SECDOMAIN_NAME     | application-security     |
     Then container log should contain Running jboss-eap-
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='elytron-integration']/*[local-name()='security-realms']/*[local-name()='elytron-realm']/@name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='elytron-integration']/*[local-name()='security-realms']/*[local-name()='elytron-realm']/@legacy-jaas-config
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security-http on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@http-authentication-factory
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value BASIC on XPath //*[local-name()='http-authentication-factory'][@name='application-security-http'][@security-domain='application-security']/*[local-name()='mechanism-configuration']/*[local-name()='mechanism'][1]/@mechanism-name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value FORM on XPath //*[local-name()='http-authentication-factory'][@name='application-security-http'][@security-domain='application-security']/*[local-name()='mechanism-configuration']/*[local-name()='mechanism'][2]/@mechanism-name
      And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value application-security on XPath //*[local-name()='security-domain'][@name='application-security'][@default-realm='application-security']/*[local-name()='realm']/@name

  Scenario: check other login modules
    Given s2i build git://github.com/wildfly/temp-eap-modules from tests/examples/test-app-extension with env and true using EAP7-1216
    Then container log should contain WFLYSRV0025
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.kie.security.jaas.KieLoginModule on XPath //*[local-name()='login-module']/@code
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value optional on XPath //*[local-name()='login-module' and @code="org.kie.security.jaas.KieLoginModule"]/@flag
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value deployment.ROOT.war on XPath //*[local-name()='login-module'][@code="org.kie.security.jaas.KieLoginModule"]/@module

  Scenario: check other login modules, galleon
    Given s2i build git://github.com/wildfly/temp-eap-modules from tests/examples/test-app-extension with env and true using EAP7-1216
      | variable                     | value       |
      | GALLEON_PROVISION_SERVER     | slim-default-server     |
    Then container log should contain WFLYSRV0025
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.kie.security.jaas.KieLoginModule on XPath //*[local-name()='login-module']/@code
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value optional on XPath //*[local-name()='login-module' and @code="org.kie.security.jaas.KieLoginModule"]/@flag
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value deployment.ROOT.war on XPath //*[local-name()='login-module'][@code="org.kie.security.jaas.KieLoginModule"]/@module

  Scenario: check other login modules, galleon legacy-security layer
    Given s2i build git://github.com/wildfly/temp-eap-modules from tests/examples/test-app-extension with env and true using EAP7-1216
      | variable                     | value       |
      | GALLEON_PROVISION_LAYERS     | cloud-server,legacy-security     |
    Then container log should contain WFLYSRV0025
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.kie.security.jaas.KieLoginModule on XPath //*[local-name()='login-module']/@code
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value optional on XPath //*[local-name()='login-module' and @code="org.kie.security.jaas.KieLoginModule"]/@flag
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value deployment.ROOT.war on XPath //*[local-name()='login-module'][@code="org.kie.security.jaas.KieLoginModule"]/@module

  Scenario: check other login modules, no security domain
    Given s2i build git://github.com/wildfly/temp-eap-modules from tests/examples/test-app-extension with env and true using EAP7-1216
      | variable                     | value            |
      | GALLEON_PROVISION_LAYERS     | cloud-server     |
    Then container log should contain WFLYCTL0030: No resource definition is registered for address
