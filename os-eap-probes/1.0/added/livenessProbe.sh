#!/bin/sh

. "$JBOSS_HOME/bin/probe_common.sh"

if [ true = "${DEBUG}" ] ; then
    # short circuit liveness check in dev mode
    exit 0
fi

OUTPUT=/tmp/liveness-output
ERROR=/tmp/liveness-error
LOG=/tmp/liveness-log

# liveness failure before management interface is up will cause the probe to fail
COUNT=30
SLEEP=5
DEBUG_SCRIPT=false
PROBE_IMPL="probe.eap.dmr.EapProbe probe.eap.dmr.HealthCheckProbe"
INITIAL_SLEEP_SECONDS=5

if [ $# -gt 0 ] ; then
    COUNT=$1
fi

# setting the first parameter to false, gets you the new default behaviour of
# count = 1, sleep = 0 and inital sleep seconds = 0
# setting it to a numeric value, or nothing falls through to the old behaviour

if [[ -n "$COUNT" && ( $COUNT = "true" || $COUNT = "false" ) ]]; then
  COUNT=1
  SLEEP=0
  INITIAL_SLEEP_SECONDS=0

  if [ $# -gt 1 ] ; then
     DEBUG_SCRIPT=$2
  fi

  if [ $# -gt 2 ] ; then
     PROBE_IMPL=$3
  fi
else
# deprecated support for count / sleep / initial sleep of 5s
    if [ $# -gt 1 ] ; then
        SLEEP=$2
    fi

    if [ $# -gt 2 ] ; then
        DEBUG_SCRIPT=$3
    fi

    if [ $# -gt 3 ] ; then
        PROBE_IMPL=$4
    fi

    if [ $# -gt 4 ] ; then
        INITIAL_SLEEP_SECONDS=$5
    fi
fi

if [ ${INITIAL_SLEEP_SECONDS} -gt 0 ]; then
    # Sleep for INITIAL_SLEEP_SECONDS (default legacy value 5) to avoid launching readiness and liveness probes
    # at the same time
    # this preserves the legacy probe behaviour when using templates that have not been updated.

    sleep ${INITIAL_SLEEP_SECONDS}
fi

if [ "$DEBUG_SCRIPT" = "true" ]; then
    DEBUG_OPTIONS="--debug --logfile $LOG --loglevel DEBUG"
fi

if python $JBOSS_HOME/bin/probes/runner.py -c READY -c NOT_READY --maxruns $COUNT --sleep $SLEEP $DEBUG_OPTIONS $PROBE_IMPL; then
    exit 0
fi

if [ "$DEBUG_SCRIPT" == "true" ]; then
  ps -ef | grep java | grep standalone | awk '{ print $2 }' | xargs kill -3
fi

exit 1

