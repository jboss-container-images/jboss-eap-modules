@jboss-eap-6 @jboss-eap-7
Feature: tests for all openshift images

  Scenario: Check that labels are correctly set
    Given image is built
    Then the image should contain label com.redhat.component containing value jboss
    Then the image should contain label com.redhat.component containing value openshift

  Scenario: Check that labels are correctly set
    Given image is built
    Then the image should contain label release
    And the image should contain label version
    And the image should contain label name
    And the image should contain label architecture with value x86_64
    And the image should contain label io.openshift.s2i.scripts-url with value image:///usr/local/s2i

  Scenario: check started as alternative UID
    # chosen by fair dice roll. guaranteed to be random.
    When container is started as uid 27558
    Then container log should contain Running
     And run id -u in container and check its output contains 27558
     And all files under /home/jboss are writeable by current user
     And run whoami in container and immediately check its output for jboss

  Scenario: check started as another alternative UID
    When container is started as uid 26458
    Then container log should contain Running
     And run id -u in container and check its output contains 26458
     And run whoami in container and immediately check its output for jboss

