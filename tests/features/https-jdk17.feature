@jboss-eap-7/eap74-openjdk17-openshift-rhel8
Feature: Check HTTPS configuration

Scenario: Configure HTTPS with an existing https-listener should give error
    When container is started with command bash
      | variable               | value        |
      | EAP_HTTPS_PASSWORD     | p@ssw0rd     |
      | EAP_HTTPS_KEYSTORE_DIR | /opt/eap     |
      | EAP_HTTPS_KEYSTORE     | keystore.jks |
      | HTTPS_KEYSTORE_TYPE     | JKS |
    Then copy features/jboss-eap-modules/scripts/https/add-https-listener-elytron.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-https-listener-elytron.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain There is already an undertow https-listener for the 'default-server' server so we are not adding it

  Scenario: Use Elytron for HTTPS (the default for JDK17)
    When container is started with env
      | variable                      | value        |
      | HTTPS_PASSWORD                | p@ssw0rd     |
      | HTTPS_KEYSTORE_DIR            | /opt/eap     |
      | HTTPS_KEYSTORE                | keystore.jks |
      | HTTPS_KEYSTORE_TYPE           | JKS          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value LocalhostSslContext on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@ssl-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='credential-reference']/@clear-text
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value JKS on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='implementation']/@type
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='file']/@path

Scenario: Https, No undertow should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                   | value         |
       | GALLEON_PROVISION_LAYERS   | core-server   |
       | EAP_HTTPS_PASSWORD         | p@ssw0rd      |
       | EAP_HTTPS_KEYSTORE_DIR     | /opt/eap      |
       | EAP_HTTPS_KEYSTORE         | keystore.jks  |
       | HTTPS_KEYSTORE_TYPE     | JKS |
    Then container log should contain You have set environment variables to configure Https. However, your base configuration does not contain the Undertow subsystem

  Scenario: Use Elytron for HTTPS, galleon s2i (the default for JDK17)
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
      | variable                      | value                       |
      | HTTPS_PASSWORD                | p@ssw0rd                    |
      | HTTPS_KEYSTORE_DIR            | /opt/eap                    |
      | HTTPS_KEYSTORE                | keystore.jks                |
      | HTTPS_KEYSTORE_TYPE           | JKS                         |
      | GALLEON_PROVISION_LAYERS      | cloud-server   |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value LocalhostSslContext on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@ssl-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='credential-reference']/@clear-text
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value JKS on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='implementation']/@type
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='file']/@path
