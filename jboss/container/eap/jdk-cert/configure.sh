#!/bin/sh
# Configure module
set -e

# Download the root certificate and update the certificates.
curl https://password.corp.redhat.com/RH-IT-Root-CA.crt -o /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt
update-ca-trust