#!/bin/sh
# Configure module
set -e

SCRIPT_DIR=$(dirname $0)
ARTIFACTS_DIR=${SCRIPT_DIR}/artifacts

chown -R jboss:root $SCRIPT_DIR
chmod -R ug+rwX $SCRIPT_DIR

pushd ${ARTIFACTS_DIR}
cp -pr * /
popd

# Remove sso content for JDK17 tech preview image. To be removed when supported.
rm "${GALLEON_FP_PATH}/src/main/resources/feature_groups/sso.xml"
rm -r "${GALLEON_FP_PATH}/src/main/resources/layers/standalone/sso"
