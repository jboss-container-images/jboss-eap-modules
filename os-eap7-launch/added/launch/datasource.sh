source $JBOSS_HOME/bin/launch/datasource-common.sh

function prepareEnv() {
  clearDatasourcesEnv
  clearTxDatasourceEnv
}

function configure() {
  inject_datasources
}

function configureEnv() {
  inject_external_datasources

  if [ -n "$JDBC_STORE_JNDI_NAME" ]; then
    local jdbcStore="<jdbc-store datasource-jndi-name=\"${JDBC_STORE_JNDI_NAME}\"/>"
    sed -i "s|<!-- ##JDBC_STORE## -->|${jdbcStore}|" $CONFIG_FILE
  fi

}

function inject_datasources() {
  # Since inject_datasources_common ends up executing in a sub-shell for where I want
  # to grab the value, use a temp file
  DEFAULT_JOB_REPOSITORY_FILE_NAME="$(mktemp /tmp/default-job-repo.XXXXXX)"

  inject_datasources_common

  local default_job_repository_pool_name
  while IFS= read -r line
  do
    default_job_repository_pool_name="${line}"
  done < "${DEFAULT_JOB_REPOSITORY_FILE_NAME}"

  if [ -n "${default_job_repository_pool_name}" ]; then
    inject_job_repository "${default_job_repository_pool_name}"
    inject_default_job_repository "${default_job_repository_pool_name}"
  else
    inject_default_job_repositories
  fi

  rm "${DEFAULT_JOB_REPOSITORY_FILE_NAME}"
  unset DEFAULT_JOB_REPOSITORY_FILE_NAME
}

function generate_datasource() {
  local pool_name="${1}"
  local jndi_name="${2}"
  local username="${3}"
  local password="${4}"
  local host="${5}"
  local port="${6}"
  local databasename="${7}"
  local checker="${8}"
  local sorter="${9}"
  local driver="${10}"
  local service_name="${11}"
  local jta="${12}"
  local validate="${13}"
  local url="${14}"

  generate_datasource_common "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" "${13}" "${14}"

  if [ -z "$service_name" ]; then
    service_name="ExampleDS"
    pool_name="ExampleDS"
    if [ -n "$DB_POOL" ]; then
      pool_name="$DB_POOL"
    fi
  fi

  if [ -n ${DEFAULT_JOB_REPOSITORY_FILE_NAME} ]; then
    # $DEFAULT_JOB_REPOSITORY_FILE_NAME will only be set for internal datasources
    if [ -n "$DEFAULT_JOB_REPOSITORY" -a "$DEFAULT_JOB_REPOSITORY" = "${service_name}" ]; then
      echo "${pool_name}" >> "${DEFAULT_JOB_REPOSITORY_FILE_NAME}"
    fi
  fi
}

# $1 - refresh-interval
function refresh_interval() {
    echo "refresh-interval=\"$1\""
}

function inject_default_job_repositories() {
  inject_default_job_repository "in-memory" "hardcoded"
}

# Arguments:
# $1 - default job repository name
function inject_default_job_repository() {
  local hardcoded="${2}"
  local dsConfMode
  getConfigurationMode "<!-- ##DEFAULT_JOB_REPOSITORY## -->" "dsConfMode"
  if [ "${dsConfMode}" = "xml" ]; then
    local defaultjobrepo="     <default-job-repository name=\"${1}\"/>"
    sed -i "s|<!-- ##DEFAULT_JOB_REPOSITORY## -->|${defaultjobrepo%$'\n'}|" $CONFIG_FILE
  elif [ "${dsConfMode}" = "cli" ]; then

    local resourceAddr="/subsystem=batch-jberet"
    if [ -z "${hardcoded}" ] ; then
      # We only need to do something when the user has explicitly set a default job repository.
      # This is because the base configuration needs to have a job repository set up for CLI 
      # replacement to work as the CLI embedded server will not even boot if it is not there.
      # (in the xml marker replacement it works differently as we replace the marker with the xml
      # for the default repo).
      # The hardcoded default-job-repository should only be set if there is a batch-jberet
      # subsystem
      echo "
      if (outcome == success) of ${resourceAddr}:read-resource
        ${resourceAddr}:write-attribute(name=default-job-repository, value=${1})
      end-if
      " >> ${CLI_SCRIPT_FILE}
    fi
  fi
}

# Arguments:
# $1 - job repository name
function inject_job_repository() {
  local dsConfMode
  getConfigurationMode "<!-- ##JOB_REPOSITORY## -->" "dsConfMode"
  if [ "${dsConfMode}" = "xml" ]; then
    local jobrepo="     <job-repository name=\"${1}\">\
        <jdbc data-source=\"${1}\"/>\
      </job-repository>\
      <!-- ##JOB_REPOSITORY## -->"

    sed -i "s|<!-- ##JOB_REPOSITORY## -->|${jobrepo%$'\n'}|" $CONFIG_FILE
  elif [ "${dsConfMode}" = "cli" ]; then
    local resourceAddr="/subsystem=batch-jberet/jdbc-job-repository=${1}"
    local jobrepo="
      if (outcome == success) of ${resourceAddr}:read-resource
        batch
        ${resourceAddr}:remove
        ${resourceAddr}:add(data-source=${1})
        run-batch
      else
        ${resourceAddr}:add(data-source=${1})
      end-if
    "
    echo "${jobrepo}" >> ${CLI_SCRIPT_FILE}
  fi

}
