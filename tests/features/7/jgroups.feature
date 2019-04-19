@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: Openshift EAP jgroups

  # CLOUD-336
  Scenario: Check if jgroups is secure
    When container is started with env
       | variable                 | value    |
       | JGROUPS_CLUSTER_PASSWORD | asdfasdf |
       | JGROUPS_PING_PROTOCOL               | openshift.DNS_PING                      |

    Then container log should contain WFLYSRV0025:
     And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='auth-protocol'][@type='AUTH']

  Scenario: Check jgroups encryption does not create invalid configuration with missing name
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_PASSWORD                     | mykeystorepass                         |
       | JGROUPS_PING_PROTOCOL                        | openshift.DNS_PING                     |
    Then container log should contain WFLYSRV0025:
     And available container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.

  Scenario: Check jgroups encryption does not create invalid configuration with missing password
    When container is started with env
       | variable                                     | value                                  |
       | JGROUPS_ENCRYPT_SECRET                       | jdg_jgroups_encrypt_secret             |
       | JGROUPS_ENCRYPT_KEYSTORE_DIR                 | /etc/jgroups-encrypt-secret-volume     |
       | JGROUPS_ENCRYPT_KEYSTORE                     | keystore.jks                           |
       | JGROUPS_ENCRYPT_NAME                         | jboss                                  |
       | JGROUPS_PING_PROTOCOL                        | openshift.DNS_PING                     |
    Then container log should contain WFLYSRV0025:
     And available container log should contain WARN Detected partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted.
