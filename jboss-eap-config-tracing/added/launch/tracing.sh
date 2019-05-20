# only processes a single environment as the placeholder is not preserved

configure() {
  local configureExtensionMode
  getConfigurationMode "<!-- ##TRACING_EXTENSION## -->" "configureExtensionMode"
  local configureSubsystemMode
  getConfigurationMode "<!-- ##TRACING_SUBSYSTEM## -->" "configureSubsystemMode"
  
  if [ "${configureExtensionMode}" = "xml" ] && [ "${configureSubsystemMode}" = "xml" ]; then
    configureByMarkers
  elif [ -n "${configureExtensionMode}" ] && [ -n "${configureSubsystemMode}" ]; then
    # As long as we did not turn off configuration we will end up here if one or both of the markers
    # were removed
    configureByCLI
  fi  
}

function configureByMarkers() {
  if [ "x${WILDFLY_TRACING_ENABLED}" == "xtrue" ]; then

    local extension="<extension module=\"org.wildfly.extension.microprofile.opentracing-smallrye\"/>"
    local subsystem="<subsystem xmlns=\"urn:wildfly:microprofile-opentracing-smallrye:1.0\"/>"

    sed -i "s|<!-- ##TRACING_EXTENSION## -->|${extension}|" $CONFIG_FILE
    sed -i "s|<!-- ##TRACING_SUBSYSTEM## -->|${subsystem}|" $CONFIG_FILE
  fi
}

function configureByCLI() {
    if [ "x${WILDFLY_TRACING_ENABLED}" == "xtrue" ]; then
      cat << 'EOF' >> ${CLI_SCRIPT_FILE}
      if (outcome != success) of /extension=org.wildfly.extension.microprofile.opentracing-smallrye:read-resource
        /extension=org.wildfly.extension.microprofile.opentracing-smallrye:add()
      end-if
      if (outcome != success) of /subsystem=microprofile-opentracing-smallrye:read-resource
        /subsystem=microprofile-opentracing-smallrye:add()
      end-if
EOF
    else
      cat << 'EOF' >> ${CLI_SCRIPT_FILE}
      if (outcome == success) of /subsystem=microprofile-opentracing-smallrye:read-resource
        /subsystem=microprofile-opentracing-smallrye:remove()
      end-if
      if (outcome == success) of /extension=org.wildfly.extension.microprofile.opentracing-smallrye:read-resource
        /extension=org.wildfly.extension.microprofile.config-smallrye:remove()
      end-if
EOF
    fi
}
