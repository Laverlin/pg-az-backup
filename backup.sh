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

echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > dump.sql.gz

echo "Create azure container $AZURE_CONTAINER_NAME"

az storage container create --auth-mode key --name $AZURE_CONTAINER_NAME 

echo "Uploading dump to $AZURE_CONTAINER_NAME"

az storage blob upload \
  --auth-mode key \
  --container-name $AZURE_CONTAINER_NAME \
  --name ${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz \
  --file dump.sql.gz

echo "SQL backup uploaded successfully"