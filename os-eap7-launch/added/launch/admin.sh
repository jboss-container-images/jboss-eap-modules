source $JBOSS_HOME/bin/launch/logging.sh 

function prepareEnv() {
  unset ADMIN_PASSWORD
  unset ADMIN_USERNAME
  unset EAP_ADMIN_PASSWORD
  unset EAP_ADMIN_USERNAME
}

function configure() {
  configure_administration
}

function configureEnv() {
  configure
}

function configure_administration() {
  if [ -n "${ADMIN_USERNAME}" -a -n "$ADMIN_PASSWORD" ]; then
    $JBOSS_HOME/bin/add-user.sh -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD"
    if [ "$?" -ne "0" ]; then
        log_error "Failed to create the management realm user $ADMIN_USERNAME"
        log_error "Exiting..."
        exit
    fi

    if grep -qF "<!-- ##MGMT_IFACE_REALM## -->" $CONFIG_FILE; then
      local mgmt_iface_replace_str="security-realm=\"ManagementRealm\""
      sed -i "s|><!-- ##MGMT_IFACE_REALM## -->| ${mgmt_iface_replace_str}>|" "$CONFIG_FILE"
    else
      cat << 'EOF' >> ${CLI_SCRIPT_FILE}
      if ( (outcome == success) && (result != undefined) && (result != ManagementRealm)) of /core-service=management/management-interface=http-interface:read-attribute(name=security-realm)
        echo "Cannot configure ManagementRealm http security realm. The http interface security realm is already configured." >> ${error_file}
        quit
      else
        /core-service=management/management-interface=http-interface:write-attribute(name=security-realm, value=ManagementRealm)
      end-if
EOF
    fi

  fi
}
