# only processes a single environment as the placeholder is not preserved

function prepareEnv() {
  unset HTTPS_NAME
  unset HTTPS_PASSWORD
  unset HTTPS_KEY_PASSWORD
  unset HTTPS_KEYSTORE_DIR
  unset HTTPS_KEYSTORE
  unset HTTPS_KEYSTORE_TYPE
}

function configure() {
  configure_https
  configure_security_domains
}

function configureEnv() {
  configure
}

function configure_https() {
  local ssl="<!-- No SSL configuration discovered -->"
  local https_connector="<!-- No HTTPS configuration discovered -->"

  if [ "${CONFIGURE_ELYTRON_SSL}" != "true" ]; then
    echo "Using PicketBox SSL configuration."
    return 
  fi

  if [ -n "${HTTPS_PASSWORD}" -a -n "${HTTPS_KEYSTORE_DIR}" -a -n "${HTTPS_KEYSTORE}" -a -n "${HTTPS_KEYSTORE_TYPE}" ]; then

    if [ -n "${HTTPS_KEY_PASSWORD}" ]; then
      key_password="<credential-reference clear-text=\"${HTTPS_KEY_PASSWORD}\"/>"
    fi

    legacy_elytron_tls="<tls>\n\
        <key-stores>\n\
            <key-store name=\"LocalhostKeyStore\">\n\
                <credential-reference clear-text=\"${HTTPS_PASSWORD}\"/>\n\
                <implementation type=\"${HTTPS_KEYSTORE_TYPE}\"/>\n\
                <file path=\"${HTTPS_KEYSTORE_DIR}/${HTTPS_KEYSTORE}\"/>\n\
            </key-store>\n\
        </key-stores>\n\
        <key-managers>\n\
            <key-manager name=\"LocalhostKeyManager\" key-store=\"LocalhostKeyStore\">\n\
                $key_password\n\
            </key-manager>\n\
        </key-managers>\n\
        <server-ssl-contexts>\n\
            <server-ssl-context name=\"LocalhostSslContext\" key-manager=\"LocalhostKeyManager\"/>\n\
        </server-ssl-contexts>\n\
    </tls>"

    elytron_tls="<tls>\n\
                <key-stores>\n\
                    <!-- ##ELYTRON_KEY_STORE## -->\n\
                </key-stores>\n\
                <key-managers>\n\
                    <!-- ##ELYTRON_KEY_MANAGER## -->\n\
                </key-managers>\n\
                <server-ssl-contexts>\n\
                    <!-- ##ELYTRON_SERVER_SSL_CONTEXT## -->\n\
                </server-ssl-contexts>\n\
            </tls>\n"

    elytron_key_store="<key-store name=\"LocalhostKeyStore\">\n\
                <credential-reference clear-text=\"${HTTPS_PASSWORD}\"/>\n\
                <implementation type=\"${HTTPS_KEYSTORE_TYPE}\"/>\n\
                <file path=\"${HTTPS_KEYSTORE_DIR}/${HTTPS_KEYSTORE}\"/>\n\
            </key-store>\n"

    elytron_key_manager="<key-manager name=\"LocalhostKeyManager\" key-store=\"LocalhostKeyStore\">$key_password</key-manager>\n"
    elytron_server_ssl_context="<server-ssl-context name=\"LocalhostSslContext\" key-manager=\"LocalhostKeyManager\"/>\n"
    elytron_https_connector="<https-listener name=\"https\" socket-binding=\"https\" ssl-context=\"LocalhostSslContext\" proxy-address-forwarding=\"true\"/>"

  elif [ -n "${HTTPS_PASSWORD}" -o -n "${HTTPS_KEYSTORE_DIR}" -o -n "${HTTPS_KEYSTORE}" -o -n "${HTTPS_KEYSTORE_TYPE}" ]; then
    echo "WARNING! Partial HTTPS configuration, the https connector WILL NOT be configured."
  fi

  # check for new config tag, use that if it's present
  grep "<!-- ##ELYTRON_TLS## -->" $CONFIG_FILE
  has_elytron_tls=$?
  if [ ${has_elytron_tls} -eq "0" ]; then # matches, its the new config
    sed -i "s|<!-- ##ELYTRON_TLS## -->|${elytron_tls}|" $CONFIG_FILE
    # remove the legacy tag, if it's present
    sed -i "s|<!-- ##TLS## -->||" $CONFIG_FILE
  fi

  grep "<!-- ##ELYTRON_KEY_STORE## -->" $CONFIG_FILE
  has_elytron_key_store=$?
  if [ ${has_elytron_key_store} -eq "0" ]; then # not already added
    sed -i "s|<!-- ##ELYTRON_KEY_STORE## -->|${elytron_key_store}<!-- ##ELYTRON_KEY_STORE## -->|" $CONFIG_FILE
    sed -i "s|<!-- ##ELYTRON_KEY_MANAGER## -->|${elytron_key_manager}<!-- ##ELYTRON_KEY_MANAGER## -->|" $CONFIG_FILE
    sed -i "s|<!-- ##ELYTRON_SERVER_SSL_CONTEXT## -->|${elytron_server_ssl_context}<!-- ##ELYTRON_SERVER_SSL_CONTEXT## -->|" $CONFIG_FILE
  else # legacy config
    sed -i "s|<!-- ##TLS## -->|${legacy_elytron_tls}|" $CONFIG_FILE
  fi
  sed -i "s|<!-- ##HTTPS_CONNECTOR## -->|${elytron_https_connector}<!-- ##HTTPS_CONNECTOR## -->|" $CONFIG_FILE
}

function configure_security_domains() {
  if [ -n "${SECDOMAIN_NAME}" ]; then
    elytron_integration="<elytron-integration>\n\
                <security-realms>\n\
                    <elytron-realm name=\"${SECDOMAIN_NAME}\" legacy-jaas-config=\"${SECDOMAIN_NAME}\"/>\n\
                </security-realms>\n\
            </elytron-integration>"
    ejb_application_security_domains="<application-security-domains>\n\
                <application-security-domain name=\"${SECDOMAIN_NAME}\" security-domain=\"${SECDOMAIN_NAME}\"/>\n\
            </application-security-domains>"
    http_application_security_domains="<application-security-domains>\n\
                <application-security-domain name=\"${SECDOMAIN_NAME}\" http-authentication-factory=\"${SECDOMAIN_NAME}-http\"/>\n\
            </application-security-domains>"
    http_authentication_factory="<http-authentication-factory name=\"${SECDOMAIN_NAME}-http\" http-server-mechanism-factory=\"global\" security-domain=\"${SECDOMAIN_NAME}\">\n\
                    <mechanism-configuration>\n\
                        <mechanism mechanism-name=\"BASIC\"/>\n\
                        <mechanism mechanism-name=\"FORM\"/>\n\
                    </mechanism-configuration>\n\
                </http-authentication-factory>"
    elytron_security_domain="<security-domain name=\"${SECDOMAIN_NAME}\" default-realm=\"${SECDOMAIN_NAME}\" permission-mapper=\"default-permission-mapper\">\n\
                    <realm name=\"${SECDOMAIN_NAME}\"/>\n\
                </security-domain>"
  fi

  sed -i "s|<!-- ##ELYTRON_INTEGRATION## -->|${elytron_integration}|" $CONFIG_FILE
  sed -i "s|<!-- ##EJB_APPLICATION_SECURITY_DOMAINS## -->|${ejb_application_security_domains}|" $CONFIG_FILE
  sed -i "s|<!-- ##HTTP_APPLICATION_SECURITY_DOMAINS## -->|${http_application_security_domains}|" $CONFIG_FILE
  sed -i "s|<!-- ##HTTP_AUTHENTICATION_FACTORY## -->|${http_authentication_factory}|" $CONFIG_FILE
  sed -i "s|<!-- ##ELYTRON_SECURITY_DOMAIN## -->|${elytron_security_domain}|" $CONFIG_FILE
}
