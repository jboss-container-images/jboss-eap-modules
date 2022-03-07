@jboss-eap-7/eap74-openjdk17-openshift-rhel8
Feature: EAP Openshift security domains

  Scenario: check security-domain configured
    Given s2i build https://github.com/jboss-openshift/openshift-examples from security-custom-configuration with env
       | variable           | value       |
       | SECDOMAIN_NAME | HiThere     |
     Then container log should contain ERROR SECDOMAIN_NAME env variable can't be set, use ELYTRON_SECDOMAIN_NAME env variable to configure authentication using Elytron.

  Scenario: check Elytron configuration with elytron core realms security domain fail
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_CORE_REALM | true                 |
     Then container log should contain WFLYSRV0025
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationDomain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain
     And check that page is served
      | property                   | value       |
      | expected_status_code       | 401         |
      | path                       | /test       |
      | port                       | 8080        |

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

 Scenario: check Elytron configuration with elytron custom security domain fail
    Given s2i build https://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-web-security with env and true using master without running
       | variable                   | value       |
       | ELYTRON_SECDOMAIN_NAME     | my-security-domain     |
       | ELYTRON_SECDOMAIN_USERS_PROPERTIES | empty-foo-users.properties                 |
       | ELYTRON_SECDOMAIN_ROLES_PROPERTIES | empty-foo-roles.properties                 |
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
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value my-security-domain on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:ejb3:')]/*[local-name()='application-security-domains']/*[local-name()='application-security-domain']/@security-domain

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
