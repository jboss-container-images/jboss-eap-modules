#!/bin/sh
# Configure module
set -e

SCRIPT_DIR=$(dirname $0)
ARTIFACTS_DIR=${SCRIPT_DIR}/artifacts

cp ${ARTIFACTS_DIR}/settings.xml $GALLEON_MAVEN_BUILD_IMG_SETTINGS_XML
