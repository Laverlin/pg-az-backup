#! /bin/sh

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

echo "set working dir"

mkdir -p /etc/data
cd /etc/data

echo $(date +"%Y-%m-%d %H:%M:%S")
echo "Creating dump of '${POSTGRES_DATABASE}' database from '${POSTGRES_HOST}'..."

pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > dump.sql.gz

printf "Trying to create azure container '${AZURE_CONTAINER_NAME}' if it does not exists "

curl -X PUT \
  -H "Content-Length: 0" \
  "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}${AZURE_SAS}&restype=container" \
  -w ": %{http_code}\n" \
  -s -o /dev/null # we no need a progress bar and an error response if the container does exist already

BACKUP_NAME="${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz"
#BACKUP_NAME="dump.sql.gz"

# store the last backup file name into marker file 
# (as a workaround since az rest api is unable to filter blobs to find the last updated, we should remember it somewhere)
#
printf "${BACKUP_NAME}" > ${LAST_BACKUP_MARKER}

echo "Uploading dump '${BACKUP_NAME}' to '${AZURE_CONTAINER_NAME}'"

#curl -X PUT -T "dump.sql.gz" \
#    -H "x-ms-date: $(date -u)" \
#    -H "x-ms-blob-type: BlockBlob" \
#    -H "Content-Length: 0" \
#    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${BACKUP_NAME}${AZURE_SAS}"

/bin/sh /app/upload.sh ${AZURE_STORAGE_ACCOUNT} ${AZURE_SAS} ${BACKUP_NAME} ${AZURE_CONTAINER_NAME}

curl -X PUT -T ${LAST_BACKUP_MARKER} -s \
    -H "x-ms-date: $(date -u)" \
    -H "x-ms-blob-type: BlockBlob" \
    "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${LAST_BACKUP_MARKER}${AZURE_SAS}"

echo "SQL backup uploaded successfully"