@jboss-eap-7/eap74-openjdk17-openshift-rhel8
Feature: Openshift EAP s2i tests

# Like above, but JDK 11 options have changed.
  # see cct_module/dynamic-resources for details.
  # Test used to add -P jboss-eap-repository-insecure,-securecentral,insecurecentral but we can't use unsecure repos, they are banned by parent pom.xml.
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Test to ensure that maven is run with -Djava.net.preferIPv4Stack=true and user-supplied arguments, even when MAVEN_ARGS is overridden, and doesn't clear the local repository after the build
    Given s2i build https://github.com/jboss-developer/jboss-eap-quickstarts from helloworld using openshift
       | variable          | value                                                                                  |
       | MAVEN_ARGS        | -e -Dcom.redhat.xpaas.repo.jbossorg -DskipTests package |
       | MAVEN_ARGS_APPEND | -Dfoo=bar                                                                              |
    Then container log should contain WFLYSRV0025
    And run sh -c 'test -d /tmp/artifacts/m2/org && echo all good' in container and immediately check its output for all good
    And s2i build log should contain -Djava.net.preferIPv4Stack=true
    And s2i build log should contain -Dfoo=bar
    And s2i build log should contain -XX:+UseParallelGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:+ExitOnOutOfMemoryError
