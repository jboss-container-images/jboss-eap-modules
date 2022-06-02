@jboss-eap-7/eap74-openjdk11-openshift-rhel8 @jboss-eap-7/eap74-openjdk8-openshift-rhel7
@jboss-eap-7/eap-xp3-openjdk11-openshift-rhel8 @jboss-eap-7/eap-xp4-openjdk11-openshift-rhel8
Feature: Tests that can't run on jdk17

  # JDK 11 images don't have xjc or wsimport
  # This one is to be ignored when running jboss-eap-7/eap74-openjdk17-openshift-rhel8
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Check that java binaries are linked properly
    When container is ready
    Then run sh -c 'test -L /usr/bin/java && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/keytool && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/rmid && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/javac && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/jar && echo "yes" || echo "no"' in container and immediately check its output for yes
     And run sh -c 'test -L /usr/bin/rmic && echo "yes" || echo "no"' in container and immediately check its output for yes

  # CLOUD-807
  # JDK 11 needs an extra dep for javax.annotations
  @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  # Nashorn removed on JDk17
  Scenario: Test if the container has the JavaScript engine available
    Given s2i build https://github.com/luck3y/openshift-examples from eap-tests/jsengine using openjdk-11
    Then container log should contain Engine found: jdk.nashorn.api.scripting.NashornScriptEngine
    And container log should contain Engine class provider found.
    And container log should not contain JavaScript engine not found.