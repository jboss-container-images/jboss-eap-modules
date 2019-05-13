@jboss-eap-7/eap72-openshift @jboss-eap-7/eap72-openjdk11-ubi8-openshift
Feature: Common EAP CD tests

  # https://issues.jboss.org/browse/CLOUD-180
  @ignore @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain Running jboss-eap-7/eap72-openshift image, version

  @ignore @jboss-eap-7-tech-preview/eap72-openjdk11-openshift @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  Scenario: Check that the labels are correctly set
    Given image is built
    Then the image should contain label com.redhat.component with value jboss-eap-7-eap72-openshift-container
     And the image should contain label name with value jboss-eap-7/eap72-openshift
     And the image should contain label io.openshift.expose-services with value 8080:http
     And the image should contain label io.openshift.tags with value builder,javaee,eap,eap7

  @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain Running jboss-eap-7/eap72-openjdk11-openshift image, version

  @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  Scenario: Check if image version and release is printed on boot
    When container is ready
    Then container log should contain Running jboss-eap-7/eap72-openjdk11-ubi8-openshift image, version

  @ignore @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Check that the labels are correctly set
    Given image is built
    Then the image should contain label com.redhat.component with value jboss-eap-7-eap72-openshift-container
     And the image should contain label name with value jboss-eap-7/eap72-openjdk11-openshift
     And the image should contain label io.openshift.expose-services with value 8080:http
     And the image should contain label io.openshift.tags with value builder,javaee,eap,eap7

  @jboss-eap-7/eap72-openjdk11-ubi8-openshift
  Scenario: Check that the labels are correctly set
    Given image is built
    Then the image should contain label com.redhat.component with value jboss-eap-7-eap72-openjdk11-ubi8-openshift-container
     And the image should contain label name with value jboss-eap-7/eap72-openjdk11-ubi8-openshift
     And the image should contain label io.openshift.expose-services with value 8080:http
     And the image should contain label io.openshift.tags with value builder,javaee,eap,eap7
