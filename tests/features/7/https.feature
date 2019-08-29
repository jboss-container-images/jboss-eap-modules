@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: Check HTTPS configuration

  # We are not able to test the following fail-fast error conditions
  #
  # * No undertow subsystem - it is too 'ingrained' to remove without changing a load of stuff
  # * No undertow servers - we cannot unset the default-server attribute so we cannot remove the default-server

  Scenario: Configure HTTPS
    When container is started with env
      | variable               | value        |
      | EAP_HTTPS_PASSWORD     | p@ssw0rd     |
      | EAP_HTTPS_KEYSTORE_DIR | /opt/eap     |
      | EAP_HTTPS_KEYSTORE     | keystore.jks |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@keystore-password
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationRealm on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@security-realm

  Scenario: Configure HTTPS with JCEKS keystore
    When container is started with env
      | variable            | value          |
      | HTTPS_PASSWORD      | p@ssw0rd       |
      | HTTPS_KEYSTORE_DIR  | /opt/eap       |
      | HTTPS_KEYSTORE      | keystore.jceks |
      | HTTPS_KEYSTORE_TYPE | JCEKS |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jceks on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@path
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value JCEKS on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@provider
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']/*[local-name()='ssl']/*[local-name()='keystore']/@keystore-password
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ApplicationRealm on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@security-realm

  Scenario: Configure HTTPS with an existing https-listener should give error
    When container is started with command bash
      | variable               | value        |
      | EAP_HTTPS_PASSWORD     | p@ssw0rd     |
      | EAP_HTTPS_KEYSTORE_DIR | /opt/eap     |
      | EAP_HTTPS_KEYSTORE     | keystore.jks |
    Then copy features/jboss-eap-modules/7/scripts/https/add-https-listener.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-https-listener.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set HTTPS_PASSWORD, HTTPS_KEYSTORE_DIR and HTTPS_KEYSTORE to add https-listeners to your undertow servers, however at least one of these already contains an https-listener. Fix your configuration.

  Scenario: Configure HTTPS with no ApplicationRealm should give error
    When container is started with command bash
      | variable               | value        |
      | EAP_HTTPS_PASSWORD     | p@ssw0rd     |
      | EAP_HTTPS_KEYSTORE_DIR | /opt/eap     |
      | EAP_HTTPS_KEYSTORE     | keystore.jks |
    Then copy features/jboss-eap-modules/7/scripts/https/remove-application-realm.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-application-realm.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set the HTTPS_PASSWORD, HTTPS_KEYSTORE_DIR and HTTPS_KEYSTORE to add the ssl server-identity. Fix your configuration to contain the /core-service=management/security-realm=ApplicationRealm resource for this to happen.

  Scenario: Configure HTTPS with exisiting SSL server-identity should give error
    When container is started with command bash
      | variable               | value        |
      | EAP_HTTPS_PASSWORD     | p@ssw0rd     |
      | EAP_HTTPS_KEYSTORE_DIR | /opt/eap     |
      | EAP_HTTPS_KEYSTORE     | keystore.jks |
    Then copy features/jboss-eap-modules/7/scripts/https/add-ssl-server-identity.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-ssl-server-identity.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set the HTTPS_PASSWORD, HTTPS_KEYSTORE_DIR and HTTPS_KEYSTORE to add the ssl server-identity. But this already exists in the base configuration. Fix your configuration.

  Scenario: Use Elytron for HTTPS
    When container is started with env
      | variable                      | value        |
      | HTTPS_PASSWORD                | p@ssw0rd     |
      | HTTPS_KEYSTORE_DIR            | /opt/eap     |
      | HTTPS_KEYSTORE                | keystore.jks |
      | HTTPS_KEYSTORE_TYPE           | JKS          |
      | CONFIGURE_ELYTRON_SSL         | true         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='security-realm'][@name="ApplicationRealm"]/*[local-name()='server-identities']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@socket-binding
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value LocalhostSslContext on XPath //*[local-name()='server'][@name="default-server"]/*[local-name()='https-listener']/@ssl-context
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value p@ssw0rd on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='credential-reference']/@clear-text
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value JKS on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='implementation']/@type
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /opt/eap/keystore.jks on XPath //*[local-name()='tls']/*[local-name()='key-stores']/*[local-name()='key-store'][@name="LocalhostKeyStore"]/*[local-name()='file']/@path
