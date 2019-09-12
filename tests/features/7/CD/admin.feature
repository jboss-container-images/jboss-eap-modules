@jboss-eap-7-tech-preview
Feature: EAP Openshift admin

  Scenario: Standard configuration, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                 | value           |
       | ADMIN_USERNAME           | kabir           |
       | ADMIN_PASSWORD           | pass            |
       | GALLEON_PROVISION_LAYERS | core-server     |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='http-interface'][@security-realm="ManagementRealm"]
    And file /opt/eap/standalone/configuration/mgmt-users.properties should contain kabir

  Scenario: check management realm extension
    Given s2i build git://github.com/wildfly/temp-eap-modules from tests/examples/test-app-extension with env and true using EAP7-1216
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='http-interface'][@security-realm="ApplicationRealm"]
