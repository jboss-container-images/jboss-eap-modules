#!/bin/bash

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"

unzip -o $SOURCES_DIR/rh-sso-7.3.1-eap7-adapter.zip -d $JBOSS_HOME
unzip -o $SOURCES_DIR/rh-sso-7.3.1-saml-eap7-adapter.zip -d $JBOSS_HOME

chown -R jboss:root $JBOSS_HOME
chmod -R g+rwX $JBOSS_HOME
