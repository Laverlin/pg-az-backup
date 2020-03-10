#! /bin/sh

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

# check all environment varibles are set
#
if [ "${AZURE_STORAGE_ACCOUNT}" = "**None**" ]; then
  echo "You need to set the AZURE_STORAGE_ACCOUNT environment variable."
  exit 1
fi

if [ "${AZURE_SAS}" = "**None**" ]; then
  echo "You need to set the AZURE_SAS environment variable."
  exit 1
fi

if [ "${AZURE_CONTAINER_NAME}" = "**None**" ]; then
  echo "You need to set the AZURE_CONTAINER_NAME environment variable."
  exit 1
fi

if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > dump.sql.gz

echo "Create azure container $AZURE_CONTAINER_NAME"

curl -X PUT	\
  -H "Content-Length: 0" \
  "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}${AZURE_SAS}&restype=container"

BACKUP_NAME="${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz"

# store the last backup file name into marker file 
# (as a workaround since az rest api is unable to filter blobs to find the last updated)
#
echo "${BACKUP_NAME}" > ${LAST_BACKUP_MARKER}

echo "Uploading dump ${BACKUP_NAME} to $AZURE_CONTAINER_NAME"

curl -X PUT -T "dump.sql.gz" \
    -H "x-ms-date: $(date -u)" \
    -H "x-ms-blob-type: BlockBlob" \
    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${BACKUP_NAME}${AZURE_SAS}"

curl -X PUT -T ${LAST_BACKUP_MARKER} \
    -H "x-ms-date: $(date -u)" \
    -H "x-ms-blob-type: BlockBlob" \
    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${LAST_BACKUP_MARKER}${AZURE_SAS}"

echo "SQL backup uploaded successfully"