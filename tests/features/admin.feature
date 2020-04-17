@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift admin

  # This can't actually be done due to
  #   [standalone@embedded /] /core-service=management/management-interface=http-interface:remove
  #   {
  #       "outcome" => "failed",
  #       "failure-description" => "WFLYRMT0025: Can't remove [
  #       (\"core-service\" => \"management\"),
  #       (\"management-interface\" => \"http-interface\")
  #   ] as JMX uses it as a remoting endpoint",
  #       "rolled-back" => true
  #   }
  @ignore
  Scenario: No http-interface
    When container is started with command bash
       | variable       | value           |
       | ADMIN_USERNAME | kabir           |
       | ADMIN_PASSWORD | pass            |
    Then copy features/jboss-eap-modules/scripts/admin/remove-http-interface.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-http-interface.cli in container once
    And file /tmp/boot.log should contain ERROR You have set environment variables to configure http-interface security-realm. Fix your configuration to contain the http-interface for this to happen.

  Scenario: Standard configuration, galleon s2i
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                 | value           |
       | ADMIN_USERNAME           | kabir           |
       | ADMIN_PASSWORD           | pass            |
       | GALLEON_PROVISION_LAYERS | core-server     |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath  //*[local-name()='http-interface'][@security-realm="ManagementRealm"]
    And file /opt/eap/standalone/configuration/mgmt-users.properties should contain kabir
