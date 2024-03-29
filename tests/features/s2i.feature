@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: Openshift EAP s2i tests

  Scenario: deploys the binary example, then checks if both war files are deployed.
    Given s2i build https://github.com/jboss-openshift/openshift-examples from binary
    Then exactly 2 times container log should contain WFLYSRV0025
    And available container log should contain WFLYSRV0010: Deployed "node-info.war"
    And file /opt/eap/standalone/deployments/node-info.war should exist
    And available container log should contain WFLYSRV0010: Deployed "top-level.war"
    And file /opt/eap/standalone/deployments/top-level.war should exist

  # Always force IPv4 (CLOUD-188)
  # Append user-supplied arguments (CLOUD-412)
  # Allow the user to clear down the maven repository after running s2i (CLOUD-413)
  @ignore @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Test to ensure that maven is run with -Djava.net.preferIPv4Stack=true and user-supplied arguments, even when MAVEN_ARGS is overridden, and doesn't clear the local repository after the build
    Given s2i build https://github.com/jboss-developer/jboss-eap-quickstarts from helloworld using openshift
       | variable          | value                                                                                  |
       | MAVEN_ARGS        | -e -P jboss-eap-repository-insecure,-securecentral,insecurecentral -Dcom.redhat.xpaas.repo.jbossorg -DskipTests package |
       | MAVEN_ARGS_APPEND | -Dfoo=bar                                                                              |
    Then container log should contain WFLYSRV0025
    And run sh -c 'test -d /tmp/artifacts/m2/org && echo all good' in container and immediately check its output for all good
    And s2i build log should contain -Djava.net.preferIPv4Stack=true
    And s2i build log should contain -Dfoo=bar
    And s2i build log should contain -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseParallelOldGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90

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
    And s2i build log should contain -XX:+UseParallelOldGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=100m -XX:+ExitOnOutOfMemoryError

  # CLOUD-458
  Scenario: Test s2i build with environment only
    Given s2i build https://github.com/jboss-openshift/openshift-examples from environment-only
    Then run sh -c 'echo FOO is $FOO' in container and check its output for FOO is Iedieve8
    And s2i build log should not contain cp: cannot stat '/tmp/src/*': No such file or directory

  # CLOUD-579
  Scenario: Test that maven is executed in batch mode
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
    | variable          | value                                                                                  |
    | MAVEN_ARGS_APPEND | -Dmaven.compiler.target=1.8 -Dmaven.compiler.source=1.8 -Dversion.war.plugin=3.3.2|
    Then s2i build log should contain --batch-mode
    And s2i build log should not contain \r

  # CLOUD-807
  @ignore @jboss-eap-7-tech-preview/eap72-openjdk11-openshift
  Scenario: Test if the container has the JavaScript engine available
    Given s2i build https://github.com/jboss-openshift/openshift-examples from eap-tests/jsengine
    Then container log should contain Engine found: jdk.nashorn.api.scripting.NashornScriptEngine
    And container log should contain Engine class provider found.
    And container log should not contain JavaScript engine not found.

  # Always force IPv4 (CLOUD-188)
  # Append user-supplied arguments (CLOUD-412)
  # Allow the user to clear down the maven repository after running s2i (CLOUD-413)
  Scenario: Test to ensure that maven is run with -Djava.net.preferIPv4Stack=true and user-supplied arguments, and clears the local repository after the build
    Given s2i build https://github.com/jboss-openshift/openshift-examples from helloworld
       | variable          | value                      |
       | MAVEN_ARGS_APPEND | -Dfoo=bar  -Dmaven.compiler.target=1.8 -Dmaven.compiler.source=1.8 -Dversion.war.plugin=3.3.2 |
       | MAVEN_LOCAL_REPO  | /home/jboss/.m2/repository |
       | MAVEN_CLEAR_REPO  | true                       |
    Then s2i build log should contain -Djava.net.preferIPv4Stack=true
    Then s2i build log should contain -Dfoo=bar
    Then run sh -c 'test -d /home/jboss/.m2/repository/org && echo oops || echo all good' in container and immediately check its output for all good

  #CLOUD-512: Copy configuration files, after the build has had a chance to generate them.
  Scenario: custom configuration deployment for existing and dynamically created files
    Given s2i build https://github.com/jboss-openshift/openshift-examples from eap-dynamic-configuration
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 1 elements on XPath //*[local-name()='root-logger']/*[local-name()='level'][@name='DEBUG']

  # CLOUD-1145 - base test
  Scenario: Check custom war file was successfully deployed via CUSTOM_INSTALL_DIRECTORIES
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | custom   |
    Then file /opt/eap/standalone/deployments/node-info.war should exist

  # CLOUD-1145 - CSV test
  Scenario: Check all modules are successfully deployed using comma-separated CUSTOM_INSTALL_DIRECTORIES value
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from custom-install-directories
      | variable   | value                    |
      | CUSTOM_INSTALL_DIRECTORIES | foo,bar  |
    Then file /opt/eap/standalone/deployments/foo.jar should exist
    Then file /opt/eap/standalone/deployments/bar.jar should exist

  # https://issues.jboss.org/browse/CLOUD-1168
  Scenario: Make sure that custom data is being copied
    Given s2i build https://github.com/jboss-developer/jboss-eap-quickstarts.git from helloworld-ws using 7.2.0.GA
      | variable    | value                           |
      | APP_DATADIR | src/main/java/org/jboss/as/quickstarts/wshelloworld |
      | MAVEN_ARGS_APPEND | -Dcom.redhat.xpaas.repo.jbossorg |
    Then file /opt/eap/standalone/data/HelloWorldService.java should exist
     And file /opt/eap/standalone/data/HelloWorldServiceImpl.java should exist
     And run stat -c "%a %n" /opt/eap/standalone/data in container and immediately check its output contains 775 /opt/eap/standalone/data

  # https://issues.jboss.org/browse/CLOUD-1143
  Scenario: Make sure that custom data is being copied even if no source code is found
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from binary
      | variable    | value                           |
      | APP_DATADIR | deployments |
    Then file /opt/eap/standalone/data/node-info.war should exist
     And run stat -c "%a %n" /opt/eap/standalone/data in container and immediately check its output contains 775 /opt/eap/standalone/data

  Scenario: Make sure SCRIPT_DEBUG triggers set -x in build
    Given s2i build https://github.com/jboss-openshift/openshift-examples.git from binary
      | variable     | value       |
      | APP_DATADIR  | deployments |
      | SCRIPT_DEBUG | true        |
    Then s2i build log should contain + log_info 'Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed'

  Scenario: check drivers added during s2i.
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-drivers with env and true
    Then container log should contain WFLYSRV0025
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='driver']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value testpostgres on XPath //*[local-name()='drivers']/*[local-name()='driver']/@name

  Scenario: Test custom settings
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-app-settings with env and true
    Then container log should contain WFLYSRV0025
    Then file /home/jboss/.m2/settings.xml should contain foo-repository

  Scenario: Test custom settings by env
    Given s2i build git://github.com/openshift/openshift-jee-sample from . with env and true using master
     | variable                     | value                                                 |
     | MAVEN_SETTINGS_XML           | /home/jboss/../jboss/../jboss/.m2/settings.xml |
    Then s2i build log should contain /home/jboss/../jboss/../jboss/.m2/settings.xml
    Then container log should contain WFLYSRV0025

  Scenario: Test embedded server configuration during S2I
    Given s2i build git://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-embedded-at-s2i with env and true using master
    Then container log should not contain WFLYCTL0056
    Then container log should contain WFLYSRV0025