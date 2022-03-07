
@jboss-eap-7 @jboss-eap-7-tech-preview
Feature: OpenShift EAP SSO tests

   Scenario: deploys the keycloak examples, then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts using 7.0.x-ose
       | variable               | value                                            |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2|
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jsp.war"
    Then container log should contain WFLYSRV0010: Deployed "app-jsp.war"
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //ns:realm/@name

   Scenario: deploys the keycloak examples using secure-deployments then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build http://github.com/jfdenise/keycloak-examples using securedeployments
       | variable                   | value                                            |
       | ARTIFACT_DIR               | app-profile-jee-saml/target,app-profile-jee/target |
       | MAVEN_ARGS_APPEND          | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2|
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee-saml.war"

   Scenario: Check default keycloak config
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target,app-profile-saml-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_PUBLIC_KEY         | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL                | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value http://localhost:8080/auth on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value / on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@logoutPage    
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 

  Scenario: Check custom keycloak config, elytron
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target,app-profile-saml-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_PUBLIC_KEY         | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL                | http://localhost:8080/auth    |
       | SSO_ENABLE_CORS        | true                          |
       | SSO_BEARER_ONLY        | true                          |
       | SSO_SAML_LOGOUT_PAGE   | /tombrady                     |
       | SSO_FORCE_LEGACY_SECURITY   | false                     |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value http://localhost:8080/auth on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /tombrady on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@logoutPage       
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 4 elements on XPath //*[local-name()='application-security-domain']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value keycloak on XPath //*[local-name()='application-security-domain']/@name

  Scenario: Check custom keycloak config
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target,app-profile-saml-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_PUBLIC_KEY         | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL                | http://localhost:8080/auth    |
       | SSO_ENABLE_CORS        | true                          |
       | SSO_BEARER_ONLY        | true                          |
       | SSO_SAML_LOGOUT_PAGE   | /tombrady                     |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value http://localhost:8080/auth on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /tombrady on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@logoutPage       
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 4 elements on XPath //*[local-name()='application-security-domain']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value keycloak on XPath //*[local-name()='application-security-domain']/@name

  Scenario: deploys the keycloak examples, then checks if it's deployed in cloud-server,sso layers.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable               | value                                            |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | cloud-server,sso |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jsp.war"
    Then container log should contain WFLYSRV0010: Deployed "app-jsp.war"
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //ns:realm/@name

    Scenario: deploys the keycloak examples, then checks for custom security domain name.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable               | value                                            |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | cloud-server,sso |
       | SSO_SECURITY_DOMAIN | foo |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jsp.war"
    Then container log should contain WFLYSRV0010: Deployed "app-jsp.war"
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //ns:realm/@name
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should have 2 elements on XPath //*[local-name()='application-security-domain']
    Then XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value foo on XPath //*[local-name()='application-security-domain']/@name

    Scenario: Check default keycloak config in cloud-server,sso layers.
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target,app-profile-saml-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_PUBLIC_KEY         | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL                | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | cloud-server,sso |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value http://localhost:8080/auth on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value / on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@logoutPage    
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 

  Scenario: Check custom keycloak config in cloud-server,sso layers.
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target,app-profile-saml-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_PUBLIC_KEY         | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL                | http://localhost:8080/auth    |
       | SSO_ENABLE_CORS        | true                          |
       | SSO_BEARER_ONLY        | true                          |
       | SSO_SAML_LOGOUT_PAGE   | /tombrady                     |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | cloud-server,sso |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value http://localhost:8080/auth on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value /tombrady on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/@logoutPage       
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 
 
  @ignore 
  # we can't provision an unsecure configuration.
  Scenario: SSO, no elytron should give error
    Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable                   | value         |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS   | management   |
    Then container log should contain You have set environment variables to enable sso. Fix your configuration to contain elytron subsystem for this to happen.

  Scenario: SSO, no undertow should give error
    Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose without running
       | variable                   | value         |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS   | core-server   |
    When container integ- is started with command bash
    # Add dummy script just for the then clause.
    Then copy features/jboss-eap-modules/scripts/sso/add-undertow-sec-domain.cli to /tmp in container
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain You have set environment variables to enable sso. Fix your configuration to contain undertow subsystem for this to happen.

  Scenario: SSO, undertow app sec domain already exists should give error
    Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose without running
       | variable                   | value         |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS   | cloud-server,sso   |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/sso/add-undertow-sec-domain.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-undertow-sec-domain.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain Undertow already contains keycloak application security domain. Fix your configuration or set SSO_SECURITY_DOMAIN env variable.

  Scenario: SSO, ejb3 app sec domain already exists should give error
    Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose without running
       | variable                   | value         |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | SSO_FORCE_LEGACY_SECURITY   | false                     |
    When container integ- is started with command bash
    Then copy features/jboss-eap-modules/scripts/sso/add-ejb3-sec-domain.cli to /tmp in container
    And run /opt/eap/bin/jboss-cli.sh --file=/tmp/add-ejb3-sec-domain.cli in container once
    And run script -c /opt/eap/bin/openshift-launch.sh /tmp/boot.log in container and detach
    And file /tmp/boot.log should contain ejb3 already contains keycloak application security domain. Fix your configuration or set SSO_SECURITY_DOMAIN env variable.

  Scenario: Check deployment is properly deployed in cloud-server,sso layers
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using 7.0.x-ose
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-profile-jee-jsp/target    |
       | SSO_REALM              | demo                                                                      |
       | SSO_URL                | http://localhost:8080/auth    |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server,sso |
    Then container log should contain Existing other application-security-domain is extended with support for keycloak
    Then container log should contain WFLYSRV0025
    And container log should contain Deployed "app-profile-jsp.war"

  Scenario: deploys the keycloak examples using secure-deployments and galleon layers then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build http://github.com/jfdenise/keycloak-examples using securedeployments
       | variable                   | value                                            |
       | ARTIFACT_DIR               | app-profile-jee/target |
       | MAVEN_ARGS_APPEND          |-Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8  -Dversion.war.maven.plugin=3.3.2 |
       | GALLEON_PROVISION_LAYERS | datasources-web-server,sso |
    Then container log should contain Existing other application-security-domain is extended with support for keycloak
    Then container log should contain WFLYSRV0025
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"

  Scenario: deploys the keycloak examples using secure-deployments CLI and galleon layers then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build http://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-sso using master
       | variable                   | value                                            |
       | ARTIFACT_DIR               | app-profile-jee/target |
       | GALLEON_PROVISION_LAYERS | datasources-web-server,sso |
    Then container log should contain Existing other application-security-domain is extended with support for keycloak
    Then container log should contain WFLYSRV0025
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jee.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https://secure-sso-demo.cloudapps.example.com/auth on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='auth-server-url']


  Scenario: deploys the keycloak examples using secure-deployments CLI then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.1 |
     Given s2i build http://github.com/jboss-container-images/jboss-eap-modules from tests/examples/test-sso using master
       | variable                   | value                                            |
       | ARTIFACT_DIR               | app-profile-jee-saml/target,app-profile-jee/target |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee-saml.war"
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jee.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='enable-cors']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value https://secure-sso-demo.cloudapps.example.com/auth on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='auth-server-url']
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jee-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value app-profile-jee-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/eap/standalone/configuration/standalone-openshift.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 

