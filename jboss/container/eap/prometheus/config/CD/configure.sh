#!/bin/sh

set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added

cp -r ${ADDED_DIR}/* ${GALLEON_FP_PATH}
