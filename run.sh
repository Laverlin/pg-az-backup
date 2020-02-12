#! /bin/sh

set -e

if [ "${SCHEDULE}" = "**None**" ]; then
  bash backup.sh
else
  exec go-cron "$SCHEDULE" /bin/bash backup.sh
fi