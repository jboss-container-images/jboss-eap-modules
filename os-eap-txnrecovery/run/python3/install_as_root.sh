set -u
set -e

SCRIPT_DIR=$(dirname $0)

cp "$SCRIPT_DIR"/*.py /opt/partition/

chown -R jboss:root /opt/partition
chmod -R 0755 /opt/partition

