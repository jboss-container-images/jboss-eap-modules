@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: EAP 7 Openshift filters

  Scenario: Filters, No undertow should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
      | variable                         | value        |
      | GALLEON_PROVISION_LAYERS         | core-server  |
      | FILTERS                          | FOO          |
      | FOO_FILTER_REF_NAME              | foo          |
      | FOO_FILTER_RESPONSE_HEADER_NAME  | Foo-Header   |
      | FOO_FILTER_RESPONSE_HEADER_VALUE | FOO          |
   Then container log should contain ERROR You have set environment variables to add undertow filters. Fix your configuration to contain the undertow subsystem for this to happen.
