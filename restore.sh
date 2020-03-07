#! /bin/bash

# The script sholud immediately fail, explicitly and loudly.
#
set -euo pipefail

# check all environment varibles are set
#
if [ "${AZURE_STORAGE_ACCOUNT}" = "**None**" ]; then
  echo "You need to set the AZURE_STORAGE_ACCOUNT environment variable."
  exit 1
fi

if [ "${AZURE_STORAGE_KEY}" = "**None**" ]; then
  echo "You need to set the AZURE_STORAGE_KEY environment variable."
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
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi


# export vars for child processes
#
export AZURE_STORAGE_ACCOUNT="$AZURE_STORAGE_ACCOUNT"
export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"


if [ "${AZURE_BLOB_NAME}" = "**None**" ]; then
  echo "Finding latest backup"
  file=$(az storage blob list \
    --container-name $AZURE_CONTAINER_NAME \
    --query 'max_by([], &properties.lastModified)' -o tsv | cut -f4)
else
  file=${AZURE_BLOB_NAME}
fi

echo "Fetching ${file} from Azure"

az storage blob download \
  --auth-mode key \
  --container-name $AZURE_CONTAINER_NAME \
  --name $file \
  --file dump.sql.gz
gzip -d dump.sql.gz

if [ "${DROP_PUBLIC}" == "yes" ]; then
	echo "Recreating the public schema"
	psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -c "drop schema public cascade; create schema public;"
fi

echo "Restoring ${file} to ${POSTGRES_DATABASE}"

psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE < dump.sql

echo "Restore complete"