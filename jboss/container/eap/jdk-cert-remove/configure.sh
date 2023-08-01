#!/bin/sh
# Configure module
set -e

# Download the root certificate and update the certificates.
rm -rf /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt
update-ca-trust