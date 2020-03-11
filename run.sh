#! /bin/sh

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

# check and prepare environment variables
#
. /process-vars.sh

if [ "${SCHEDULE}" = "**None**" ]; then
    if [ "${RESTORE}" = "yes" ]; then
        echo "run restore"
        /bin/sh /restore.sh
    else
        echo "run backup"
        /bin/sh /backup.sh
    fi
else
    echo "schedule backup $SCHEDULE"
    JOB="$SCHEDULE /bin/sh /backup.sh > /proc/1/fd/1 2>/proc/1/fd/2"
    echo "$JOB" > /etc/crontabs/root
    crond -f -d 8 
fi
