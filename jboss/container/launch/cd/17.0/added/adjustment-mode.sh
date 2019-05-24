# The mode used to do the environment variable replacement. The values are:
# -none     - no adjustment should be done. This cam be forced if $CONFIG_IS_FINAL = true
#               is passed in when starting the container
# -xml      - adjustment will happen via the legacy xml marker replacement
# -cli      - adjustment will happen via cli commands
# -xml_cli  - adjustment will happen via xml marker replacement if the marker is found. If not,
#               it will happen via cli commands
#
# Handling of the meanings of this are done by the
CONFIG_ADJUSTMENT_MODE="xml_cli"
if [ "${CONFIG_IS_FINAL^^}" = "TRUE" ]; then
    CONFIG_ADJUSTMENT_MODE="none"
fi

# Whether or not we should ignore xml markers
CLI_SCRIPT_ONLY_IGNORE_MARKERS=false


# Takes the following parameters:
# - $1      - the xml marker to test for
#
# Returns one of the following three values
# - ""      - no configuration should be done via the variables
# - "xml"   - configuration should happen via marker replacement
# - "cli"   - configuration should happen via cli commands
#
function getConfigurationMode() {
  local marker="${1}"
  unset -v "$2" || echo "Invalid identifier: $2" >&2

  local attemptXml="false"
  local viaCli="false"
  if [ "${CONFIG_ADJUSTMENT_MODE,,}" = "xml" ]; then
    attemptXml="true"
  elif  [ "${CONFIG_ADJUSTMENT_MODE,,}" = "cli" ]; then
    viaCli="true"
  elif  [ "${CONFIG_ADJUSTMENT_MODE,,}" = "xml_cli" ]; then
    attemptXml="true"
    viaCli="true"
  elif [ "${CONFIG_ADJUSTMENT_MODE,,}" != "none" ]; then
    echo "Bad CONFIG_ADJUSTMENT_MODE \'${CONFIG_ADJUSTMENT_MODE}\'"
    exit 1
  fi

  local configVia=""
  if [ "${attemptXml}" = "true" ]; then
    if grep -Fq "${marker}" $CONFIG_FILE; then
        configVia="xml"
    fi
  fi

  if [ -z "${configVia}" ]; then
    if [ "${viaCli}" = "true" ]; then
        configVia="cli"
    fi
  fi

  printf -v "$2" '%s' "${configVia}"
}