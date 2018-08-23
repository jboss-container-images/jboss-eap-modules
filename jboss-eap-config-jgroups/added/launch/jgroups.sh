# only processes a single environment as the placeholder is not preserved

source $JBOSS_HOME/bin/launch/logging.sh

function prepareEnv() {
  unset JGROUPS_ENCRYPT_SECRET
  unset JGROUPS_ENCRYPT_PASSWORD
  unset JGROUPS_ENCRYPT_KEYSTORE_DIR
  unset JGROUPS_ENCRYPT_KEYSTORE
  unset JGROUPS_ENCRYPT_NAME
}

function configure() {
  configure_jgroups_encryption
}

function configureEnv() {
  configure
}

function configure_jgroups_encryption() {
  jgroups_encrypt=""

  if [ -n "${JGROUPS_ENCRYPT_SECRET}" ]; then
    if [ -n "${JGROUPS_ENCRYPT_NAME}" -a -n "${JGROUPS_ENCRYPT_PASSWORD}" ] ; then
      # the elytron skelton config. This will be used to replace <!-- ##ELYTRON_TLS## -->
      # if this is replaced, we'll also remove the legacy <!-- ##TLS## --> marker
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

      # For new JGroups we need to use SYM_ENCRYPT protocol

      # first add the elytron key-store:
      key_store="<key-store name=\"${JGROUPS_ENCRYPT_KEYSTORE}\">\n\
                    <credential-reference clear-text=\"${JGROUPS_ENCRYPT_PASSWORD}\"/>\n\
                    <implementation type=\"${JGROUPS_ENCRYPT_KEYSTORE_TYPE:-JCEKS}\"/>\n\
                    <file path=\"${JGROUPS_ENCRYPT_KEYSTORE_DIR}/${JGROUPS_ENCRYPT_KEYSTORE}\"/>\n\
                </key-store>\n"

      jgroups_encrypt="\
        <encrypt-protocol type=\"SYM_ENCRYPT\" key-store=\"${JGROUPS_ENCRYPT_KEYSTORE}\" key-alias=\"${JGROUPS_ENCRYPT_NAME}\">\
          <key-credential-reference clear-text=\"${JGROUPS_ENCRYPT_PASSWORD}\"/>\
          <property name=\"encrypt_entire_message\">${JGROUPS_ENCRYPT_ENTIRE_MESSAGE:-true}</property>\
        </encrypt-protocol>"

      # compatability with old marker
      jgroups_legacy_encrypt="\
        <protocol type=\"SYM_ENCRYPT\">\
          <property name=\"provider\">SunJCE</property>\
          <property name=\"sym_algorithm\">AES</property>\
          <property name=\"encrypt_entire_message\">true</property>\
          <property name=\"keystore_name\">${JGROUPS_ENCRYPT_KEYSTORE_DIR}/${JGROUPS_ENCRYPT_KEYSTORE}</property>\
          <property name=\"store_password\">${JGROUPS_ENCRYPT_PASSWORD}</property>\
          <property name=\"alias\">${JGROUPS_ENCRYPT_NAME}</property>\
        </protocol>"

    else
      log_warning "Partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted."
    fi
  fi

  # check for new config tag, use that if it's present
  grep "<!-- ##ELYTRON_TLS## -->" $CONFIG_FILE
  has_elytron_tls=$? # 0 == matches found, 1 == no matches, 2 == error
  if [ ${has_elytron_tls} -eq "0" ]; then # matches, its the new config
    sed -i "s|<!-- ##ELYTRON_TLS## -->|${elytron_tls}|" $CONFIG_FILE
    # remove the legacy tag, if it's present
    sed -i "s|<!-- ##TLS## -->||" $CONFIG_FILE
  fi

  grep "<!-- ##ELYTRON_KEY_STORE## -->" $CONFIG_FILE
  has_elytron_key_store=$?
  if [ ${has_elytron_key_store} -eq "0" ]; then # already been added
    sed -i "s|<!-- ##ELYTRON_KEY_STORE## -->|${key_store}<!-- ##ELYTRON_KEY_STORE## -->|" $CONFIG_FILE
    sed -i "s|<!-- ##JGROUPS_ENCRYPT## -->|$jgroups_encrypt|g" "$CONFIG_FILE"
  else
    sed -i "s|<!-- ##JGROUPS_ENCRYPT## -->|$jgroups_legacy_encrypt|g" "$CONFIG_FILE"
  fi


}
