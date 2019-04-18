function prepareEnv() {
  unset SECDOMAIN_NAME
  unset SECDOMAIN_USERS_PROPERTIES
  unset SECDOMAIN_ROLES_PROPERTIES
  unset SECDOMAIN_LOGIN_MODULE
  unset SECDOMAIN_PASSWORD_STACKING
}

function configure() {
  configure_security_domains
}

function configureEnv() {
  configure
}


configure_security_domains() {
  local usersProperties="\${jboss.server.config.dir}/${SECDOMAIN_USERS_PROPERTIES}"
  local rolesProperties="\${jboss.server.config.dir}/${SECDOMAIN_ROLES_PROPERTIES}"

  # CLOUD-431: Check if provided files are absolute paths
  test "${SECDOMAIN_USERS_PROPERTIES:0:1}" = "/" && usersProperties="${SECDOMAIN_USERS_PROPERTIES}"
  test "${SECDOMAIN_ROLES_PROPERTIES:0:1}" = "/" && rolesProperties="${SECDOMAIN_ROLES_PROPERTIES}"

  local domains="<!-- no additional security domains configured -->"

  if [ -n "$SECDOMAIN_NAME" ]; then
      local login_module=${SECDOMAIN_LOGIN_MODULE:-UsersRoles}
      local realm=""
      local stack=""

      if grep -Fq "<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->" $CONFIG_FILE; then
        if [ $login_module == "RealmUsersRoles" ]; then
            realm="<module-option name=\"realm\" value=\"ApplicationRealm\"/>"
        fi

        if [ -n "$SECDOMAIN_PASSWORD_STACKING" ]; then
            stack="<module-option name=\"password-stacking\" value=\"useFirstPass\"/>"
        fi

        domains="\
          <security-domain name=\"$SECDOMAIN_NAME\" cache-type=\"default\">\
              <authentication>\
                  <login-module code=\"$login_module\" flag=\"required\">\
                      <module-option name=\"usersProperties\" value=\"${usersProperties}\"/>\
                      <module-option name=\"rolesProperties\" value=\"${rolesProperties}\"/>\
                      $realm\
                      $stack\
                  </login-module>\
              </authentication>\
          </security-domain>"

        sed -i "s|<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|${domains}<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|" "$CONFIG_FILE"

        configure_elytron_integration 0
        configure_elytron_security_domain 0
        configure_http_authentication_factory 0
        configure_http_application_security_domains 0
        configure_ejb_application_security_domains 0
      else
        local moduleOpts=("(\"usersProperties\"=>\""${usersProperties}"\")"
                          "(\"rolesProperties\"=>\""${rolesProperties}"\")")

        if [ $login_module == "RealmUsersRoles" ]; then
            moduleOpts+=("(\"realm\"=>\"ApplicationRealm\")")
        fi

        if [ -n "$SECDOMAIN_PASSWORD_STACKING" ]; then
            moduleOpts+=("(\"password-stacking\"=>\"useFirstPass\")")
        fi

        cat << EOF >> ${CLI_SCRIPT_FILE}
        /subsystem=security/security-domain=${SECDOMAIN_NAME}:add(cache-type=default)
        /subsystem=security/security-domain=${SECDOMAIN_NAME}/authentication=classic:add(login-modules=[{
          code=RealmUsersRoles, flag=required, module=RealmUsersRoles, module-options=[$(IFS=,; echo "{${moduleOpts[*]}}")]
        }])
EOF
        #Keep always this order!
        #TODO: This does not work yet, issue with embedded server, we cannot configure elytron security domain in admin-mode
        configure_elytron_integration 1
        configure_elytron_security_domain 1
        configure_http_authentication_factory 1
        configure_http_application_security_domains 1
        configure_ejb_application_security_domains 1
      fi
  fi
}

function configure_elytron_integration() {
   declare cliForced="$1"

   if [ $cliForced -eq 0 ] && grep -Fq "<!-- ##ELYTRON_INTEGRATION## -->" $CONFIG_FILE; then
      local elytron_integration="<elytron-integration>\n\
                <security-realms>\n\
                    <elytron-realm name=\"${SECDOMAIN_NAME}\" legacy-jaas-config=\"${SECDOMAIN_NAME}\"/>\n\
                </security-realms>\n\
            </elytron-integration>"

      sed -i "s|<!-- ##ELYTRON_INTEGRATION## -->|${elytron_integration}|" $CONFIG_FILE
   else
     cat << EOF >> ${CLI_SCRIPT_FILE}
     if (outcome == success) of /subsystem=elytron:read-resource
      /subsystem=security/elytron-realm=${SECDOMAIN_NAME}:add(legacy-jaas-config=${SECDOMAIN_NAME})
    end-if
EOF
   fi
}

function configure_elytron_security_domain() {
  declare cliForced="$1"

  if [ $cliForced -eq 0 ] && grep -Fq "<!-- ##ELYTRON_SECURITY_DOMAIN## -->" $CONFIG_FILE; then
    loca elytron_security_domain="<security-domain name=\"${SECDOMAIN_NAME}\" default-realm=\"${SECDOMAIN_NAME}\" permission-mapper=\"default-permission-mapper\">\n\
                    <realm name=\"${SECDOMAIN_NAME}\"/>\n\
                </security-domain>"

    sed -i "s|<!-- ##ELYTRON_SECURITY_DOMAIN## -->|${elytron_security_domain}|" $CONFIG_FILE
  else
    #This requires that the security subsystem is available, it will fail otherwise
    cat << EOF >> ${CLI_SCRIPT_FILE}
      if (outcome == success) of /subsystem=elytron:read-resource
        /subsystem=elytron/security-domain=my-sec-domain:add(realms=[{realm=my-sec-domain}],default-realm=my-sec-domain,permission-mapper=default-permission-mapper)
      end-if
EOF
  fi
}



function configure_http_authentication_factory() {
  declare cliForced="$1"

  if [ $cliForced -eq 0 ] && grep -Fq "<!-- ##HTTP_AUTHENTICATION_FACTORY## -->" $CONFIG_FILE; then
    local http_authentication_factory="<http-authentication-factory name=\"${SECDOMAIN_NAME}-http\" http-server-mechanism-factory=\"global\" security-domain=\"${SECDOMAIN_NAME}\">\n\
                    <mechanism-configuration>\n\
                        <mechanism mechanism-name=\"BASIC\"/>\n\
                        <mechanism mechanism-name=\"FORM\"/>\n\
                    </mechanism-configuration>\n\
                </http-authentication-factory>"

    sed -i "s|<!-- ##HTTP_AUTHENTICATION_FACTORY## -->|${http_authentication_factory}|" $CONFIG_FILE
  else
    cat << EOF >> ${CLI_SCRIPT_FILE}
      if (outcome == success) of /subsystem=elytron:read-resource
         /subsystem=elytron/http-authentication-factory=${SECDOMAIN_NAME}-http:add(
            http-server-mechanism-factory=global,security-domain=${SECDOMAIN_NAME},mechanism-configurations=[{mechanism-name=BASIC},{mechanism-name=FORM}]
          )
      end-if
EOF
  fi
}

function configure_http_application_security_domains() {
  declare cliForced="$1"

  if [ $cliForced -eq 0 ] && grep -Fq "<!-- ##HTTP_APPLICATION_SECURITY_DOMAINS## -->" $CONFIG_FILE; then
    local http_application_security_domains="<application-security-domains>\n\
                <application-security-domain name=\"${SECDOMAIN_NAME}\" http-authentication-factory=\"${SECDOMAIN_NAME}-http\"/>\n\
            </application-security-domains>"

    sed -i "s|<!-- ##HTTP_APPLICATION_SECURITY_DOMAINS## -->|${http_application_security_domains}|" $CONFIG_FILE
  else
  cat << EOF >> ${CLI_SCRIPT_FILE}
    if (outcome == success) of /subsystem=undertow:read-resource
      /subsystem=undertow/application-security-domain=${SECDOMAIN_NAME}:add(security-domain=${SECDOMAIN_NAME})
    end-if
EOF
  fi
}

function configure_ejb_application_security_domains() {
  declare cliForced="$1"

  if [ $cliForced -eq 0 ] && grep -Fq "<!-- ##EJB_APPLICATION_SECURITY_DOMAINS## -->" $CONFIG_FILE; then
    local ejb_application_security_domains="<application-security-domains>\n\
                <application-security-domain name=\"${SECDOMAIN_NAME}\" security-domain=\"${SECDOMAIN_NAME}\"/>\n\
            </application-security-domains>"

    sed -i "s|<!-- ##EJB_APPLICATION_SECURITY_DOMAINS## -->|${ejb_application_security_domains}|" $CONFIG_FILE
  else
    cat << EOF >> ${CLI_SCRIPT_FILE}
    if (outcome == success) of /subsystem=ejb3:read-resource
      /subsystem=ejb3/application-security-domain=${SECDOMAIN_NAME}:add(security-domain=${SECDOMAIN_NAME})
    end-if
EOF
  fi
}
