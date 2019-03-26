set -u
set -e

SCRIPT_DIR=$(dirname $0)

cp "$SCRIPT_DIR"/*.py /opt/partition/

chmod 755 /opt/partition/*
