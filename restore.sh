#! /bin/sh

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

# attempt to define backup file name
#
if [ "${AZURE_BLOB_NAME}" = "**None**" ]; then
  echo "Finding latest backup"
  backup_file=$(curl -X GET -s \
    -H "x-ms-date: $(date -u)" \
    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${LAST_BACKUP_MARKER}${AZURE_SAS}")
else
  backup_file=${AZURE_BLOB_NAME}
fi

echo "Fetching '${backup_file}' from Azure"

curl -X GET -f \
    -H "x-ms-date: $(date -u)" \
    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${backup_file}${AZURE_SAS}" \
    -o dump.sql.gz

gzip -d dump.sql.gz

if [ "${DROP_PUBLIC}" == "yes" ]; then
	echo "Recreating the public schema"
	psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -c "drop schema public cascade; create schema public;"
fi

if [ "${DROP_PUBLIC}" == "create" ]; then
	echo "Creating the new database"
	psql $POSTGRES_HOST_OPTS -c "create database \"$POSTGRES_DATABASE\";"
fi

echo "Restoring '${backup_file}' to '${POSTGRES_DATABASE}'"

psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE < dump.sql

echo "Restore complete"