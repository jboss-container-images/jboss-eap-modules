@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift admin

  Scenario: Standard configuration
    When container is started with env
       | variable       | value           |
       | ADMIN_USERNAME | kabir           |
       | ADMIN_PASSWORD | pass            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value ManagementRealm on XPath //*[local-name()='http-interface']/@security-realm
    And file /opt/eap/standalone/configuration/mgmt-users.properties should contain kabir


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
    Then copy features/jboss-eap-modules/7/scripts/admin/remove-http-interface.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-http-interface.cli in container once
    And file /tmp/boot.log should contain ERROR You have set environment variables to configure http-interface security-realm. Fix your configuration to contain the http-interface for this to happen.
