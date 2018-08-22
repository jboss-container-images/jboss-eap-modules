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
    else
      log_warning "Partial JGroups encryption configuration, the communication within the cluster WILL NOT be encrypted."
    fi
  fi

  sed -i "s|<!-- ##ELYTRON_KEY_STORE## -->|${key_store}<!-- ##ELYTRON_KEY_STORE## -->|" $CONFIG_FILE
  sed -i "s|<!-- ##JGROUPS_ENCRYPT## -->|$jgroups_encrypt|g" "$CONFIG_FILE"
}
