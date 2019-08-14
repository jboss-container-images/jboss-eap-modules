@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift port offset

  Scenario: Zero port offset in base configuration
    When container is started with env
       | variable    | value           |
       | PORT_OFFSET | 1000            |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 1000 on XPath //*[local-name()='socket-binding-group']/@port-offset

  Scenario: Port offset is different from non-zero value in base configuration
    When container is started with command bash
       | variable    | value           |
       | PORT_OFFSET | 900             |
    Then copy features/jboss-eap-modules/7/scripts/ports/port-offset-500.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/port-offset-500.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 900 on XPath //*[local-name()='socket-binding-group']/@port-offset
    And file /tmp/boot.log should contain WARN You specified PORT_OFFSET=900 while the base configuration's value for the port-offset resolves to a different non-zero value. 900 will be used as the port offset.
    # Short version of the string above to use as a sanity test in the next test
    And file /tmp/boot.log should contain WARN You specified PORT_OFFSET

  Scenario: Port offset is same as non-zero value in base configuration
    When container is started with command bash
       | variable    | value           |
       | PORT_OFFSET | 500             |
    Then copy features/jboss-eap-modules/7/scripts/ports/port-offset-500.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/port-offset-500.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value 500 on XPath //*[local-name()='socket-binding-group']/@port-offset
    And file /tmp/boot.log should not contain WARN You specified PORT_OFFSET

