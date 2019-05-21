# only processes a single environment as the placeholder is not preserved

source $JBOSS_HOME/bin/launch/logging.sh

function prepareEnv() {
  unset HTTPS_NAME
  unset HTTPS_PASSWORD
  unset HTTPS_KEYSTORE_DIR
  unset HTTPS_KEYSTORE
  unset HTTPS_KEYSTORE_TYPE
}

function configure() {
  configure_https
}

function configureEnv() {
  configure
}

function configure_https() {
  if [ "${CONFIGURE_ELYTRON_SSL}" == "true" ]; then
    echo "Using Elytron for SSL configuration."
    return 
  fi

  local valid="false"
  if [ -n "${HTTPS_PASSWORD}" -a -n "${HTTPS_KEYSTORE_DIR}" -a -n "${HTTPS_KEYSTORE}" ]; then
    valid="true"
  elif [ -n "${HTTPS_PASSWORD}" -o -n "${HTTPS_KEYSTORE_DIR}" -o -n "${HTTPS_KEYSTORE}" ]; then
    log_warning "Partial HTTPS configuration, the https connector WILL NOT be configured."
  fi

  configureSsl "${valid}"
  configureHttps "${valid}"
}

function configureSsl() {
  local valid="${1}"
  local configureMode
  getConfigurationMode "<!-- ##SSL## -->" "configureMode"

  if [ ${configureMode} = "xml" ]; then
    configureSslXml "${valid}"
  elif [ ${configureMode} = "cli" ]; then
    configureSslCli "${valid}"
  fi
}

function configureSslXml() {
  local ssl="<!-- No SSL configuration discovered -->"
  local valid="${1}"
  if [ ${valid} = "true" ]; then
    if [ -n "$HTTPS_KEYSTORE_TYPE" ]; then
      keystore_provider="provider=\"${HTTPS_KEYSTORE_TYPE}\""
    fi
    ssl="<server-identities>\n\
                    <ssl>\n\
                        <keystore ${keystore_provider} path=\"${HTTPS_KEYSTORE_DIR}/${HTTPS_KEYSTORE}\" keystore-password=\"${HTTPS_PASSWORD}\"/>\n\
                    </ssl>\n\
                </server-identities>"
  fi
  sed -i "s|<!-- ##SSL## -->|${ssl}|" $CONFIG_FILE
}

function configureSslCli() {
  if [ ${valid} != "true" ]; then
    return
  fi
  local ssl_resource="/core-service=management/security-realm=ApplicationRealm/server-identity=ssl"
  
  local ssl_add="$ssl_resource:add(keystore-path=\"${HTTPS_KEYSTORE_DIR}/${HTTPS_KEYSTORE}\", keystore-password=\"${HTTPS_PASSWORD}\""
  if [ -n "$HTTPS_KEYSTORE_TYPE" ]; then
    ssl_add="${ssl_add}, keystore-provider=\"${HTTPS_KEYSTORE_TYPE}\""
  fi
  ssl_add="${ssl_add})"

  local ssl="
  if (outcome == success) of $ssl_resource:read-resource
    batch
    ${ssl_resource}:remove
    ${ssl_add}
    run-batch
  else
    ${ssl_add}
  end-if
  "
  cat << EOF >> ${CLI_SCRIPT_FILE}
    ${ssl}
EOF
}

function configureHttps() {
  local valid="${1}"
  local configureMode
  getConfigurationMode "<!-- ##HTTPS_CONNECTOR## -->" "configureMode"

  if [ ${configureMode} = "xml" ]; then
    configureHttpsXml "${valid}"
  elif [ ${configureMode} = "cli" ]; then
    configureHttpsCli "${valid}"
  fi
}

function configureHttpsXml() {
  local https_connector="<!-- No HTTPS configuration discovered -->"
  local valid="${1}"
  if [ ${valid} = "true" ]; then
    https_connector="<https-listener name=\"https\" socket-binding=\"https\" security-realm=\"ApplicationRealm\" proxy-address-forwarding=\"true\"/>"
  fi
  sed -i "s|<!-- ##HTTPS_CONNECTOR## -->|${https_connector}|" $CONFIG_FILE     
}

function configureHttpsCli() {
  local valid="${1}"
  if [ ${valid} != "true" ]; then
    return
  fi
  # Add the https listener to all undertow servers
  local https_connector="
   for serverName in /subsystem=undertow:read-children-names(child-type=server)
    if (result == []) of /subsystem=undertow/server=\$serverName:read-children-names(child-type=https-listener)
      /subsystem=undertow/server=\$serverName/https-listener=https:add(security-realm=ApplicationRealm, socket-binding=https, proxy-address-forwarding=true)
    else
      echo \"There is already an undertow https-listener for the '\$serverName' server so we are not adding it\" 
    end-if
  done
"
  cat << EOF >> ${CLI_SCRIPT_FILE}
	  ${https_connector}
EOF
}