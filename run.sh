#! /bin/sh

set -euo pipefail

if [ "${SCHEDULE}" = "**None**" ]; then
    echo "run backup"
    bash backup.sh
else
    echo "schedule backup $SCHEDULE"
    exec go-cron "$SCHEDULE" /bin/bash backup.sh
fi
