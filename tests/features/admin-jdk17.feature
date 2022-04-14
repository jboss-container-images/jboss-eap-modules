@jboss-eap-7/eap74-openjdk17-openshift-rhel8
Feature: EAP Openshift admin

  Scenario: Standard configuration
    When container is started with env
       | variable       | value           |
       | ADMIN_USERNAME | kabir           |
       | ADMIN_PASSWORD | pass            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value management-http-authentication on XPath //*[local-name()='http-interface']/@http-authentication-factory
    And file /opt/eap/standalone/configuration/mgmt-users.properties should contain kabir

  Scenario: Standard configuration, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                 | value           |
       | ADMIN_USERNAME           | kabir           |
       | ADMIN_PASSWORD           | pass            |
       | GALLEON_PROVISION_LAYERS | core-server     |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='http-interface'][@security-realm="ManagementRealm"]
    And file /opt/eap/standalone/configuration/mgmt-users.properties should contain kabir