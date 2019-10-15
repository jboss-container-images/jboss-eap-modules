@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP Openshift deployment-scanner tests

  Scenario: Server started with AUTO_DEPLOY_EXPLODED=true should work
    When container is started with env
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | true          |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner' and not(@name)]/@auto-deploy-exploded

  Scenario: Server started with AUTO_DEPLOY_EXPLODED=false should work
    When container is started with env
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | false         |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner' and not(@name)]/@auto-deploy-exploded

  Scenario: If more than one deployment scanner all should be adjusted
    When container is started with command bash
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | true          |
    Then copy features/jboss-eap-modules/scripts/deployment-scanner/add-deployment-scanner.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-deployment-scanner.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner' and not(@name)]/@auto-deploy-exploded
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner' and @name='x']/@auto-deploy-exploded

  Scenario: No deployment-scanner subsystem should give failure
    When container is started with command bash
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | true          |
    Then copy features/jboss-eap-modules/scripts/deployment-scanner/remove-deployment-scanner-subsystem.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-deployment-scanner-subsystem.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set environment variables to set auto-deploy-exploded for the deployment scanner. Fix your configuration to contain the deployment-scanner subsystem for this to happen.

  Scenario: No deployment scanners in the deployment-scanner subsystem should give failure
    When container is started with command bash
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | true          |
    Then copy features/jboss-eap-modules/scripts/deployment-scanner/remove-deployment-scanner.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/remove-deployment-scanner.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set environment variables to set auto-deploy-exploded for the deployment scanner. Fix your configuration to contain at least one deployment-scanner in the deployment-scanner subsystem for this to happen.

    Scenario: Deployment scanner with matching auto-deploy-exploded value should pass
      When container is started with command bash
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | true          |
    Then copy features/jboss-eap-modules/scripts/deployment-scanner/set-default-deployment-scanner-to-true.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/set-default-deployment-scanner-to-true.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should not contain ERROR You have set environment variables to set auto-deploy-exploded for the deployment scanner but your configuration already contains a conflicting value. Fix your configuration.
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:deployment-scanner:')]/*[local-name()='deployment-scanner' and not(@name)]/@auto-deploy-exploded

  Scenario: Deployment scanner with clashing auto-deploy-exploded value should give failure
      When container is started with command bash
       | variable                   | value         |
       | AUTO_DEPLOY_EXPLODED       | false         |
    Then copy features/jboss-eap-modules/scripts/deployment-scanner/set-default-deployment-scanner-to-true.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/set-default-deployment-scanner-to-true.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set environment variables to set auto-deploy-exploded for the deployment scanner but your configuration already contains a conflicting value. Fix your configuration.
