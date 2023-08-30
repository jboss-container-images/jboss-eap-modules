#!/bin/sh
# Configure module
set -e

# Download the root certificate and update the certificates.
rm -rf /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt
rm -rf /etc/pki/ca-trust/source/anchors/2022-IT-Root-CA.pem
update-ca-trust
