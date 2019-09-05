@jboss-eap-7-tech-preview
Feature: Check HTTPS configuration

# Enable when EAP CD 18 is in use, core-security-realms layer is required.
@ignore
  Scenario: Configure HTTPS, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
      | variable                           | value                       |
      | GALLEON_PROVISION_LAYERS           | cloud-profile,core-server   |
      | EAP_HTTPS_PASSWORD                 | p@ssw0rd                    |
      | EAP_HTTPS_KEYSTORE_DIR             | /opt/eap                    |
      | EAP_HTTPS_KEYSTORE                 | keystore.jks                |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@keystore-password
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationRealm on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@security-realm

  Scenario: Https, No undertow should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                   | value         |
       | GALLEON_PROVISION_LAYERS   | core-server   |
       | EAP_HTTPS_PASSWORD         | p@ssw0rd      |
       | EAP_HTTPS_KEYSTORE_DIR     | /opt/eap      |
       | EAP_HTTPS_KEYSTORE         | keystore.jks  |
    Then container log should contain You have set HTTPS_PASSWORD, HTTPS_KEYSTORE_DIR and HTTPS_KEYSTORE to add an undertow https-listener. Fix your configuration to contain the undertow subsystem for this to happen.

  Scenario: Use Elytron for HTTPS, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
      | variable                      | value                       |
      | HTTPS_PASSWORD                | p@ssw0rd                    |
      | HTTPS_KEYSTORE_DIR            | /opt/eap                    |
      | HTTPS_KEYSTORE                | keystore.jks                |
      | HTTPS_KEYSTORE_TYPE           | JKS                         |
      | CONFIGURE_ELYTRON_SSL         | true                        |
      | GALLEON_PROVISION_LAYERS      | core-server,cloud-profile   |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value LocalhostSslContext on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@ssl-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='credential-reference']/@clear-text
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value JKS on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='implementation']/@type
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='file']/@path
