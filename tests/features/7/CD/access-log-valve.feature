@jboss-eap-7-tech-preview
Feature: EAP Openshift access-log-valve and log handler tests

  Scenario: Access Log valve, No undertow should give error
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
       | variable                   | value         |
       | GALLEON_PROVISION_LAYERS   | core-server   |
       | ENABLE_ACCESS_LOG          | true          |
       | ENABLE_ACCESS_LOG_TRACE    | true          |
   Then container log should contain ERROR You have set ENABLE_ACCESS_LOG=true to add the access-log valve. Fix your configuration to contain the undertow subsystem for this to happen.
