function configure() {
  configure_json_logging
}

function configure_json_logging() {
  sed -i "s|^.*\.module=org\.jboss\.logmanager\.ext$||" $LOGGING_FILE
  local configureMode
  getConfigurationMode "##CONSOLE-FORMATTER##" "configureMode"
  if [ "${configureMode}" = "xml" ]; then
    configureByMarkers
  elif [ "${configureMode}" = "cli" ]; then
    configureByCLI
  fi
}

function configureByMarkers() {
  if [ "${ENABLE_JSON_LOGGING^^}" == "TRUE" ]; then
    sed -i 's|##CONSOLE-FORMATTER##|OPENSHIFT|' $CONFIG_FILE
    sed -i 's|##CONSOLE-FORMATTER##|OPENSHIFT|' $LOGGING_FILE
  else
    sed -i 's|##CONSOLE-FORMATTER##|COLOR-PATTERN|' $CONFIG_FILE
    sed -i 's|##CONSOLE-FORMATTER##|COLOR-PATTERN|' $LOGGING_FILE
  fi
}

function configureByCLI() {
  if [ "${ENABLE_JSON_LOGGING^^}" == "TRUE" ]; then
    cat <<'EOF' >> ${CLI_SCRIPT_FILE}
      if (outcome != success) of /subsystem=logging/json-formatter=OPENSHIFT:read-resource
        /subsystem=logging/json-formatter=OPENSHIFT:add(exception-output-type=formatted, key-overrides=[timestamp="@timestamp"], meta-data=[@version=1])
      else
        /subsystem=logging/json-formatter=OPENSHIFT:write-attribute(name=exception-output-type, value=formatted)
        /subsystem=logging/json-formatter=OPENSHIFT:write-attribute(name=key-overrides, value=[timestamp="@timestamp"]
        /subsystem=logging/json-formatter=OPENSHIFT:write-attribute(name=meta-data, value=[@version=1])
      end-if
EOF
    consoleHandlerName "OPENSHIFT" >> ${CLI_SCRIPT_FILE}
    sed -i 's|##CONSOLE-FORMATTER##|OPENSHIFT|' $LOGGING_FILE
  else
    local color_pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"
cat <<EOF >> ${CLI_SCRIPT_FILE}
      if (outcome != success) of  /subsystem=logging/pattern-formatter=COLOR-PATTERN:read-resource
        /subsystem=logging/pattern-formatter=COLOR-PATTERN:add(pattern="${color_pattern}")
      else
        /subsystem=logging/pattern-formatter=COLOR-PATTERN:write-attribute(name=pattern, value="${color_pattern}")
      end-if
EOF
    consoleHandlerName "COLOR-PATTERN" >> ${CLI_SCRIPT_FILE}
    sed -i 's|##CONSOLE-FORMATTER##|COLOR-PATTERN|' $LOGGING_FILE
  fi
}

function consoleHandlerName() {
  declare name="$1"
  local result=""

  read -r -d '' result <<EOF
    if (outcome != success) of /subsystem=logging/console-handler=CONSOLE:read-resource
      /subsystem=logging/console-handler=CONSOLE:add(named-formatter=${name})
    else
      /subsystem=logging/console-handler=CONSOLE:write-attribute(name=named-formatter, value=${name})
    end-if
EOF

  echo "$result"
}
