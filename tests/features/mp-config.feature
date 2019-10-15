@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift mp-config tests

  Scenario: Micro-profile config, configuration with defaults
    When container is started with env
       | variable                                | value         |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /home/jboss on XPath //*[local-name()='config-source'][@name='config-map']/*[local-name()='dir']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 500 on XPath //*[local-name()='config-source' and @name='config-map']/@ordinal

  Scenario: Micro-profile config configuration
    When container is started with env
       | variable                                | value         |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss   |
       | MICROPROFILE_CONFIG_DIR_ORDINAL         | 88            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /home/jboss on XPath //*[local-name()='config-source' and @name='config-map']/*[local-name()='dir']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 88 on XPath //*[local-name()='config-source' and @name='config-map']/@ordinal

  Scenario: Micro-profile config configuration, config-source already exists
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and False using master without running
       | variable                                | value           |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss     |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/mp-config/add-config-source.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-config-source.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain Cannot configure Microprofile Config. MICROPROFILE_CONFIG_DIR was specified but there is already a config-source named config-map configured.

  Scenario: Micro-profile config configuration, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                                | value           |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss     |
       | MICROPROFILE_CONFIG_DIR_ORDINAL         | 88              |
       | GALLEON_PROVISION_LAYERS                | cloud-server   |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /home/jboss on XPath //*[local-name()='config-source' and @name='config-map']/*[local-name()='dir']/@path
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 88 on XPath //*[local-name()='config-source' and @name='config-map']/@ordinal

  Scenario: Micro-profile config configuration, no subsystem
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                       | value           |
       | MICROPROFILE_CONFIG_DIR        | /home/jboss     |
       | GALLEON_PROVISION_LAYERS       | web-server      |
    Then container log should contain You have set MICROPROFILE_CONFIG_DIR to configure a config-source. Fix your configuration to contain the microprofile-config subsystem for this to happen.