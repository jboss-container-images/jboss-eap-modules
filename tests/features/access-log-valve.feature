@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift access-log-valve and log handler tests

  # Missing tests
  # The scripts give errors on a few corner cases:
  #
  # * No servers/hosts
  # This is not possible to test because we cannot remove them because the subsystem references these from
  # the default-virtual-host and default-server attributes. Trying to undefine these reports success,
  # but a subsequent :read-resource shows this to not actually take effect
  # Also this is not possible to test with a s2i provisioned server with no undertow since the undertow module
  # is missing

  Scenario: Standard configuration
    When container is started with env
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    # Just check this once for the scenarios which don't have ENABLE_ACCESS_LOG_TRACE=true
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']

  Scenario: Standard configuration with log handler enabled
    When container is started with env
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
       | ENABLE_ACCESS_LOG_TRACE    | true          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRACE on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']/*[local-name()='level']/@name

  Scenario: Added server with no hosts should not have access-log valve to the added server
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-empty-server.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-empty-server.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='server']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='server' and @name='new-server']
    # We just ignore the servers which have no host since they are not really useable anyway
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 0 elements on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host']


  Scenario: Added server with two hosts should have acesss-log added to both the new hosts
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-server-with-two-hosts.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-server-with-two-hosts.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='server']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='server' and @name='new-server']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newA']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newA']/*[local-name()='access-log']/@use-server-log
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newB']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newB']/*[local-name()='access-log']/@use-server-log

  Scenario: Existing access-log with matching values should not give error
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-matching-access-log.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-matching-access-log.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h %l %u %t %{i,X-Forwarded-Host} "%r" %s %b on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    And file /tmp/boot.log should not contain You have set ENABLE_ACCESS_LOG=true to add the access-log valve. However there is already one for

  Scenario: Existing access-log with clashing values should give error
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-clashing-access-log.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-access-log.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value %h on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@pattern
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='access-log']/@use-server-log
    And file /tmp/boot.log should contain You have set ENABLE_ACCESS_LOG=true to add the access-log valve. However there is already one for /subsystem=undertow/server=default-server/host=default-host/setting=access-log which has conflicting values. Fix your configuration.

  Scenario: Existing logger category with matching level should not give error
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
       | ENABLE_ACCESS_LOG_TRACE    | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-matching-logger.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-matching-logger.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value TRACE on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']/*[local-name()='level']/@name
    And file /tmp/boot.log should not contain ERROR You have set ENABLE_ACCESS_LOG=true to add the access log logger category

  Scenario: Existing logger category with clashing level should not give error
    When container is started with command bash
       | variable                   | value         |
       | ENABLE_ACCESS_LOG          | true          |
       | ENABLE_ACCESS_LOG_TRACE    | true          |
    Then copy features/jboss-eap-modules/scripts/access-log-valve/add-clashing-logger.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-logger.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value WARN on XPath //*[local-name()='logger' and @category='org.infinispan.rest.logging.RestAccessLoggingHandler']/*[local-name()='level']/@name
    And file /tmp/boot.log should contain You have set ENABLE_ACCESS_LOG=true to add the access log logger category 'org.infinispan.rest.logging.RestAccessLoggingHandler'. However one already exists which has conflicting values. Fix your configuration to contain the logging subsystem for this to happen.

  Scenario: Access Log valve, No undertow should give error
    Given s2i build git://github.com/jfdenise/openshift-jee-sample from . with env and true using master
       | variable                   | value         |
       | GALLEON_PROVISION_LAYERS   | core-server   |
       | ENABLE_ACCESS_LOG          | true          |
       | ENABLE_ACCESS_LOG_TRACE    | true          |
   Then container log should contain ERROR You have set ENABLE_ACCESS_LOG=true to add the access-log valve. Fix your configuration to contain the undertow subsystem for this to happen.
