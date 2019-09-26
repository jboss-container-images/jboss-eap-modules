#!/bin/bash
# Set up Hawkular for java s2i builder image
set -e
mkdir -p /opt/jboss/container/eap/s2i/
ln -s /opt/jboss/container/wildfly/s2i/install-common/install-common.sh /opt/jboss/container/eap/s2i/install-common.sh

chown -h jboss:root /opt/jboss/container/eap/s2i/install-common.sh