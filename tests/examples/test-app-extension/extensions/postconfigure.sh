#!/bin/bash

if [ "${SCRIPT_DEBUG}" = "true" ] ; then
    set -x
    echo "Script debugging is enabled, allowing bash commands and their arguments to be printed as they are executed"
fi
source "${JBOSS_HOME}/bin/launch/login-modules-common.sh"
configure_login_modules "org.kie.security.jaas.KieLoginModule" "optional" "deployment.ROOT.war"
