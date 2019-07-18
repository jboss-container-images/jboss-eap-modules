@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift datasources with adjusted base config
@wip
  Scenario: ExampleDS already in config is not changed
    #wildfly-cekit-modules has been updated to only add the default ds if ENABLE_GENERATE_DEFAULT_DATASOURCE=true
    When container is started with command bash
       | variable                           | value           |
       | ENABLE_GENERATE_DEFAULT_DATASOURCE | true            |
    Then copy features/jboss-eap-modules/7/scripts/datasource/add-example-datasource-with-non-std-jndi-name.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-example-datasource-with-non-std-jndi-name.cli in container
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='datasource']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='xa-datasource']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value java:jboss/datasources/ExampleDS-original on XPath //*[local-name()='datasource']/@jndi-name
