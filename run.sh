#! /bin/sh
set -euo pipefail

if [ "${SCHEDULE}" = "**None**" ]; then
    echo "run backup"
    /bin/bash backup.sh
else
    echo "schedule backup $SCHEDULE"
    JOB="$SCHEDULE /bin/bash /backup.sh > /proc/1/fd/1 2>/proc/1/fd/2"
    echo "$JOB" > /etc/crontabs/root
    crond -f -d 8 
fi
