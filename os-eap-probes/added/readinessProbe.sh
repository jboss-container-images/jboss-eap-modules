#!/bin/bash

. "$JBOSS_HOME/bin/probe_common.sh"

OUTPUT=/tmp/readiness-output
ERROR=/tmp/readiness-error
LOG=/tmp/readiness-log
OCPVERS=/tmp/readiness-ocp-version

COUNT=30
SLEEP=5
DEBUG=${SCRIPT_DEBUG:-false}
PROBE_IMPL="probe.eap.dmr.EapProbe probe.eap.dmr.HealthCheckProbe"
TMPLOC=${TMPDIR:-/tmp}

if [ $# -gt 0 ] ; then
    COUNT=$1
fi

# check if this is OCP 4 (k8s 13+)
# avoid querying the api every time if we can.
is_ocp4="false"
if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
    if [ -f ${OCPVERS} ]; then
        is_ocp4=$(<${OCPVERS})
    else
        is_ocp4=$(is_ocp4_or_greater)
        echo ${is_ocp4} > ${OCPVERS}
    fi
fi

# COUNT is unset, and we're running on OCP 4+ OR COUNT is set to either true or false
if [[ ( $# -eq 0 && ${is_ocp4} = "true" ) || -n "$COUNT" && ( $COUNT = "true" || $COUNT = "false" ) ]]; then
  COUNT=1
  SLEEP=0

  if [ $# -gt 1 ] ; then
     DEBUG=$2
  fi

  if [ $# -gt 2 ] ; then
        PROBE_IMPL=$3
  fi
else
    if [ $# -gt 0 ]; then
        # deprecated support for count / sleep
        if [ ! -f ${TMPLOC}/probe_deprecation_warning ]; then
            # log a warning the first time this happens and at least one parameter has been specified.
            touch ${TMPLOC}/probe_deprecation_warning
            echo "WARN: Support for count / sleep has been deprecated in probes and may be removed in a future release."
        fi
    fi

    if [ $# -gt 1 ] ; then
        SLEEP=$2
    fi

    if [ $# -gt 2 ] ; then
        DEBUG=$3
    fi

    if [ $# -gt 3 ] ; then
        PROBE_IMPL=$4
    fi
fi

if [ "$DEBUG" = "true" ]; then
    DEBUG_OPTIONS="--debug --logfile $LOG --loglevel DEBUG"
fi

if python $JBOSS_HOME/bin/probes/runner.py -c READY --maxruns $COUNT --sleep $SLEEP $DEBUG_OPTIONS $PROBE_IMPL; then
    exit 0
fi
exit 1

