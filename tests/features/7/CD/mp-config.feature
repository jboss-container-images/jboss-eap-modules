@jboss-eap-7-tech-preview
Feature: EAP Openshift mp-config tests

  Scenario: Micro-profile config configuration, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                                | value           |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss     |
       | MICROPROFILE_CONFIG_DIR_ORDINAL         | 88              |
       | GALLEON_PROVISION_LAYERS                | cloud-profile   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /home/jboss on XPath //*[local-name()='config-source' and @name='config-map']/*[local-name()='dir']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 88 on XPath //*[local-name()='config-source' and @name='config-map']/@ordinal

  Scenario: Micro-profile config configuration, no subsystem
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                       | value           |
       | MICROPROFILE_CONFIG_DIR        | /home/jboss     |
       | GALLEON_PROVISION_LAYERS       | web-server      |
    Then container log should contain You have set MICROPROFILE_CONFIG_DIR to configure a logger. Fix your configuration to contain the microprofile-config subsystem for this to happen.