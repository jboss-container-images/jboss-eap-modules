@jboss-eap-7 @jboss-eap-6
Feature: Openshift common test
  Scenario: Check jolokia port is available
    When container is ready
    Then check that port 8778 is open
    Then inspect container
       | path                    | value       |
       | /Config/ExposedPorts    | 8778/tcp    |

  Scenario: Enable Access Log
    When container is started with env
      | variable          | value            |
      | ENABLE_ACCESS_LOG | true             |
    Then container log should contain INFO Configuring Access Log Valve.

  Scenario: Test Default Access Log behavior
    When container is ready
    Then container log should not contain Configuring Access Log Valve.
    And container log should contain Access log is disabled, ignoring configuration.

  # CLOUD-1017: Option to enable script debugging
  Scenario: Check that script debugging (set -x) can be enabled
    When container is started with env
       | variable     | value |
       | SCRIPT_DEBUG | true  |
    Then container log should contain + echo 'Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed'

  # CLOUD-427: we need to ensure jboss.node.name doesn't go beyond 23 chars
  Scenario: Check that long node names are truncated to 23 characters
    When container is started with env
       | variable  | value                      |
       | NODE_NAME | abcdefghijklmnopqrstuvwxyz |
    Then container log should contain jboss.node.name = defghijklmnopqrstuvwxyz

  Scenario: Check that node name is used
    When container is started with env
       | variable  | value                      |
       | NODE_NAME | abcdefghijk                |
    Then container log should contain jboss.node.name = abcdefghijk

  # https://issues.jboss.org/browse/CLOUD-912
  Scenario: Check that java binaries are linked properly
    When container is ready
    Then run sh -c 'test -L /usr/bin/java && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/keytool && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/rmid && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/javac && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/jar && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/rmic && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/xjc && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/wsimport && echo "yes" || echo "no"' in container and immediately check its output for yes
