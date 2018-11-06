@jboss-eap-7/eap71-openshift
Feature: Openshift EAP jgroups

  Scenario: jgroups-encrypt
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_SECRET                       | eap_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
    Then container log should contain WFLYSRV0039:
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /etc/jgroups-encrypt-secret-volume/keystore.jks on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='keystore_name']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value jboss on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='alias']
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value mykeystorepass on XPath //*[local-name()='protocol'][@type='SYM_ENCRYPT']/*[local-name()='property'][@name='store_password']
     # https://issues.jboss.org/browse/CLOUD-1189
     # Make sure the SYM_ENCRYPT protocol is specified before pbcast.NAKACK2 for udp stack
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pbcast.NAKACK2 on XPath //*[local-name()='stack'][@name='udp']/*[local-name()='protocol'][@type='SYM_ENCRYPT']/following-sibling::*[1]/@type
     # Make sure the SYM_ENCRYPT protocol is specified before pbcast.NAKACK2 for tcp stack
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value pbcast.NAKACK2 on XPath //*[local-name()='stack'][@name='tcp']/*[local-name()='protocol'][@type='SYM_ENCRYPT']/following-sibling::*[1]/@type
