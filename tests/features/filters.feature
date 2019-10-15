@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP 7 Openshift filters

  Scenario: CLOUD-2877, RHDM-520, RHPAM-1434, test default filter ref name
    When container is started with env
      | variable                         | value      |
      | FILTERS                          | FOO        |
      | FOO_FILTER_RESPONSE_HEADER_NAME  | Foo-Header |
      | FOO_FILTER_RESPONSE_HEADER_VALUE | FOO        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Foo-Header on XPath //*[local-name()='host']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Foo-Header on XPath //*[local-name()='filters']/*[local-name()='response-header']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Foo-Header on XPath //*[local-name()='filters']/*[local-name()='response-header']/@header-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value FOO on XPath //*[local-name()='filters']/*[local-name()='response-header']/@header-value

  Scenario: CLOUD-2877, RHDM-520, RHPAM-1434, test specific filter ref name
    When container is started with env
      | variable                         | value      |
      | FILTERS                          | FOO        |
      | FOO_FILTER_REF_NAME              | foo        |
      | FOO_FILTER_RESPONSE_HEADER_NAME  | Foo-Header |
      | FOO_FILTER_RESPONSE_HEADER_VALUE | FOO        |
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value foo on XPath //*[local-name()='host']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value foo on XPath //*[local-name()='filters']/*[local-name()='response-header']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Foo-Header on XPath //*[local-name()='filters']/*[local-name()='response-header']/@header-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value FOO on XPath //*[local-name()='filters']/*[local-name()='response-header']/@header-value

  Scenario: With multiple servers and hosts, the filter-ref gets added to all hosts. Also do two sets of filters
    When container is started with command bash
      | variable                         | value      |
      | FILTERS                          | ONE,TWO    |
      | ONE_FILTER_RESPONSE_HEADER_NAME  | One-Header |
      | ONE_FILTER_RESPONSE_HEADER_VALUE | One-Val    |
      | TWO_FILTER_REF_NAME              | two        |
      | TWO_FILTER_RESPONSE_HEADER_NAME  | Two-Header |
      | TWO_FILTER_RESPONSE_HEADER_VALUE | Two-Val    |
    Then copy features/jboss-eap-modules/scripts/filters/add-server-with-two-hosts.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-server-with-two-hosts.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='filters']/*[local-name()='response-header']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value One-Header on XPath //*[local-name()='filters']/*[local-name()='response-header' and @name='One-Header']/@header-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value One-Val on XPath //*[local-name()='filters']/*[local-name()='response-header' and @name='One-Header']/@header-value
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Two-Header on XPath //*[local-name()='filters']/*[local-name()='response-header' and @name='two']/@header-name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value Two-Val on XPath //*[local-name()='filters']/*[local-name()='response-header' and @name='two']/@header-value
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='server']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:jboss:domain:undertow:')]/*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='filter-ref']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value One-Header on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value two on XPath //*[local-name()='server' and @name='default-server']/*[local-name()='host' and @name='default-host']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='server' and @name='new-server']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newA']/*[local-name()='filter-ref']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value One-Header on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newA']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value two on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newA']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newB']/*[local-name()='filter-ref']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value One-Header on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newB']/*[local-name()='filter-ref']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value two on XPath //*[local-name()='server' and @name='new-server']/*[local-name()='host' and @name='newB']/*[local-name()='filter-ref']/@name

 Scenario: Base config with an existing response-header filter with matching values should pass
    When container is started with command bash
      | variable                         | value      |
      | FILTERS                          | ONE        |
      | ONE_FILTER_RESPONSE_HEADER_NAME  | One-Header |
      | ONE_FILTER_RESPONSE_HEADER_VALUE | One-Val    |
    Then copy features/jboss-eap-modules/scripts/filters/add-matching-response-header-filter.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-matching-response-header-filter.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should not contain ERROR You have set environment variables to add an undertow response-header filter called

 Scenario: Base config with an existing response-header filter with clashing values should give an error
    When container is started with command bash
      | variable                         | value      |
      | FILTERS                          | ONE        |
      | ONE_FILTER_RESPONSE_HEADER_NAME  | One-Header |
      | ONE_FILTER_RESPONSE_HEADER_VALUE | One-Val    |
    Then copy features/jboss-eap-modules/scripts/filters/add-clashing-response-header-filter.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-response-header-filter.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set environment variables to add an undertow response-header filter called One-Header. However there is already one which has conflicting values. Fix your configuration.

 Scenario: Base config with an existing filter-ref with the same name should give an error
    When container is started with command bash
      | variable                         | value      |
      | FILTERS                          | ONE        |
      | ONE_FILTER_RESPONSE_HEADER_NAME  | One-Header |
      | ONE_FILTER_RESPONSE_HEADER_VALUE | One-Val    |
    Then copy features/jboss-eap-modules/scripts/filters/add-matching-response-header-filter.cli to /tmp in container
    Then copy features/jboss-eap-modules/scripts/filters/add-clashing-filter-ref.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-matching-response-header-filter.cli in container once
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-clashing-filter-ref.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ERROR You have set environment variables to add an undertow filter-ref called One-Header but one already exists. Fix your configuration so it does not contain clashing filter-refs for this to happen.

  Scenario: Filters, No undertow should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
      | variable                         | value        |
      | GALLEON_PROVISION_LAYERS         | core-server  |
      | FILTERS                          | FOO          |
      | FOO_FILTER_REF_NAME              | foo          |
      | FOO_FILTER_RESPONSE_HEADER_NAME  | Foo-Header   |
      | FOO_FILTER_RESPONSE_HEADER_VALUE | FOO          |
   Then container log should contain ERROR You have set environment variables to add undertow filters. Fix your configuration to contain the undertow subsystem for this to happen.
