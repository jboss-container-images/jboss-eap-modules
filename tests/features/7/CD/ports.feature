@jboss-eap-7-tech-preview
Feature: EAP Openshift port offset

  Scenario: Zero port offset in galleon provisioned configuration
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                    | value           |
       | PORT_OFFSET                 | 1000            |
       | GALLEON_PROVISION_LAYERS    | web-server      |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 1000 on XPath //*[local-name()='socket-binding-group']/@port-offset
