function log_warning() {
  local message="${1}"

  echo >&2 -e "WARN ${message}"
}

function log_error() {
  local message="${1}"

  echo >&2 -e "ERROR ${message}"
}

function log_info() {
  local message="${1}"

  echo >&2 -e "INFO ${message}"
}
