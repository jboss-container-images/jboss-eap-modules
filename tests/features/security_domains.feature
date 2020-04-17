@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift security domains

  @ignore
  # ignored for now, there are additional domains that match this in the default config now
  Scenario: check security-domain unconfigured
    When container is started with env
       | variable                  | value       |
       | UNRELATED_ENV_VARIABLE    | whatever    |
    Then container log should contain Running jboss-eap-
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <!-- no additional security domains configured -->
    # 3 OOTB are: jboss-web-policy; jboss-ejb-policy; other
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='subsystem'][/*[local-name()='security-domains']/*[local-name()='security-domain']

     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='subsystem'][@xmlns='urn:jboss:domain:security:2.0']/*[local-name()='security-domains']/*[local-name()='security-domain']

  @ignore
  # matches additional security-domain elements, needs to be revisited
  Scenario: check security-domain unconfigured with prefix
    When container is started with env
       | variable                  | value       |
       | UNRELATED_ENV_VARIABLE    | whatever    |
    Then file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <!-- no additional security domains configured -->
    # 3 OOTB are: jboss-web-policy; jboss-ejb-policy; other
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 3 elements on XPath //*[local-name()='security-domain']
  
  # this test is no more valid, we are not adding comments in standalone-openshift.xml
  @ignore
  Scenario: check security-domain unconfigured
    When container is started with env
       | variable                  | value       |
       | UNRELATED_ENV_VARIABLE    | whatever    |
    Then container log should contain Running jboss-eap-
     And file /opt/eap/standalone/configuration/standalone-openshift.xml should contain <!-- no additional security domains configured -->

  Scenario: check other login modules, galleon legacy-security layer
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-extension with env and true
      | variable                     | value       |
      | GALLEON_PROVISION_LAYERS     | cloud-server,legacy-security     |
    Then container log should contain WFLYSRV0025
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value org.kie.security.jaas.KieLoginModule on XPath //*[local-name()='login-module']/@code
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value optional on XPath //*[local-name()='login-module' and @code="org.kie.security.jaas.KieLoginModule"]/@flag
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value deployment.ROOT.war on XPath //*[local-name()='login-module'][@code="org.kie.security.jaas.KieLoginModule"]/@module

  Scenario: check other login modules, no security domain
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-extension with env and true
      | variable                     | value            |
      | GALLEON_PROVISION_LAYERS     | cloud-server     |
    Then container log should contain WFLYCTL0030: No resource definition is registered for address

  Scenario: check Elytron configuration with elytron core realms security domain success
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_CORE_REALM | true                 |
    When container integ- is started with command bash
    Then run /opt/eap/bin/add-user.sh -a -u jfdenise -p pass -g Admin -sc /opt/eap/standalone/configuration in container once    
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And check that port 8080 is open
    And check that page is served
      | property                   | value       |
      | path                       | /test       |
      | port                       | 8080        |
      | username | jfdenise |
      | password | pass |

  Scenario: check Elytron configuration with elytron core realms security domain fail, galleon
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_CORE_REALM | true                 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server                 |
     Then container log should contain WFLYSRV0025
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain
     And check that page is served
      | property                   | value       |
      | expected_status_code       | 401         |
      | path                       | /test       |
      | port                       | 8080        |

  Scenario: check Elytron configuration with elytron core realms security domain success, galleon
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_CORE_REALM | true                 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server                 |
    When container integ- is started with command bash
    Then run /opt/eap/bin/add-user.sh -a -u jfdenise -p pass -g Admin -sc /opt/eap/standalone/configuration in container once    
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And check that port 8080 is open
    And check that page is served
      | property                   | value       |
      | path                       | /test       |
      | port                       | 8080        |
      | username | jfdenise |
      | password | pass |

  Scenario: check Elytron configuration with elytron custom security domain success
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_USERS_PROPERTIES | foo-users.properties                 |
       | ELYTRON_SECDOMAIN_ROLES_PROPERTIES | foo-roles.properties                 |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/security_domains/foo-users.properties to /opt/eap/standalone/configuration/ in container    
    Then copy features/jboss-eap-modules/scripts/security_domains/foo-roles.properties to /opt/eap/standalone/configuration/ in container    
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And check that port 8080 is open
    And check that page is served
      | property                   | value       |
      | path                       | /test       |
      | port                       | 8080        |
      | username | jfdenise |
      | password | pass |

 Scenario: check Elytron configuration with elytron custom security domain fail, galleon
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_USERS_PROPERTIES | empty-foo-users.properties                 |
       | ELYTRON_SECDOMAIN_ROLES_PROPERTIES | empty-foo-roles.properties                 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server                 |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/security_domains/empty-foo-users.properties to /opt/eap/standalone/configuration/ in container    
    Then copy features/jboss-eap-modules/scripts/security_domains/empty-foo-roles.properties to /opt/eap/standalone/configuration/ in container    
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And check that port 8080 is open
    And check that page is served
      | property                   | value       |
      | expected_status_code       | 401         |
      | path                       | /test       |
      | port                       | 8080        |
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain

  Scenario: check Elytron configuration with elytron custom security domain success, galleon
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_USERS_PROPERTIES | foo-users.properties                 |
       | ELYTRON_SECDOMAIN_ROLES_PROPERTIES | foo-roles.properties                 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/security_domains/foo-users.properties to /opt/eap/standalone/configuration/ in container    
    Then copy features/jboss-eap-modules/scripts/security_domains/foo-roles.properties to /opt/eap/standalone/configuration/ in container    
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And check that port 8080 is open
    And check that page is served
      | property                   | value       |
      | path                       | /test       |
      | port                       | 8080        |
      | username | jfdenise |
      | password | pass |
