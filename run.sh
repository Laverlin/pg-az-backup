#! /bin/bash

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

# check and prepare environment variables
#
. /app/process-vars.sh

if [ "${SCHEDULE}" = "**None**" ]; then
    if [ "${RESTORE}" = "yes" ]; then
        echo "run restore"
        /bin/bash /app/restore.sh
    else
        echo "run backup"
        /bin/bash /app/backup.sh
    fi
else
    echo "schedule backup $SCHEDULE"
    JOB="$SCHEDULE /bin/bash /app/backup.sh > /proc/1/fd/1 2>/proc/1/fd/2"
    echo "$JOB" > /etc/crontabs/root
    crond -f -d 8 
fi
