# PG-AZ-Backup

[![Build Status](https://img.shields.io/docker/cloud/build/ilaverlin/pg-backup)](https://hub.docker.com/repository/docker/ilaverlin/pg-backup)   ![Image Size](https://img.shields.io/docker/image-size/ilaverlin/pg-backup/latest)

Docker image to easily backup specified Postgres database to Azure BLOB storage and restore that database from the BLOB. Periodic backup is also supported.

## Usage
Before upload the backup to the azure container you'll need to [Create an Azure Storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal) and get [SAS token](https://docs.microsoft.com/en-us/azure/storage/common/storage-sas-overview)  

#### Backup database
```
docker run \
    -e POSTGRES_HOST=<postgres hostname> \
    -e POSTGRES_USER=<postgres db user> \
    -e POSTGRES_PASSWORD=<postgres db password> \
    -e POSTGRES_DATABASE=<database name> \
    -e AZURE_STORAGE_ACCOUNT=<storage account name> \
    -e AZURE_SAS=<azure SAS token> \
    -e AZURE_STORAGE_CONTAINER=<azure storage container> \
    --rm \
    ilaverlin/bg-az-backup
```
Also, you may pass additional backup parameters by setting an environment variable `POSTGRES_EXTRA_OPTS` 

#### Automatic periodic backup
To schedule a periodic backup you'll need to pass `SCHEDULE` environment variable that should contain cron job schedule syntax, e. g. `-e SCHEDULE="@daily"` or `-e SCHEDULE = "0 0 * * 0"` (weekly)
Do not forget to add `-d` switch to **docker run** command to keep the container running 
```
docker run \
    -e POSTGRES_HOST=<postgres hostname> \
    -e POSTGRES_USER=<postgres db user> \
    -e POSTGRES_PASSWORD=<postgres db password> \
    -e POSTGRES_DATABASE=<database name> \
    -e AZURE_STORAGE_ACCOUNT=<storage account name> \
    -e AZURE_SAS=<azure SAS token> \
    -e AZURE_STORAGE_CONTAINER=<azure storage container> \
    -e SCHEDULE=<cron schedule> \
    -d --name pg-scheduled-backup \
    ilaverlin/bg-az-backup
```
#### Restore database
To restore database you'll need to set environment variable `RESTORE` to 'yes' e. g. `-e RESTORE="yes"`. If the target database contains data, you might want to specify `DROP_PUBLIC="yes"`, that will drop the public schema. In case of an empty target database you can omit this variable.
By default the last backup will be restored. If you need to restore specified backup you can set AZURE_BLOB_NAME environment variable with backp file name e.g. `-e AZURE_BLOB_NAME="<database name>_2020-03-11T14:08:28Z.sql.gz"`
```
docker run \
    -e POSTGRES_HOST=<postgres hostname> \
    -e POSTGRES_USER=<postgres db user> \
    -e POSTGRES_PASSWORD=<postgres db password> \
    -e POSTGRES_DATABASE=<database name> \
    -e AZURE_STORAGE_ACCOUNT=<storage account name> \
    -e AZURE_SAS=<azure SAS token> \
    -e AZURE_STORAGE_CONTAINER=<azure storage container> \
    -e RESTORE=yes \
    -e DROP_PUBLIC=yes \
    --rm \
    ilaverlin/bg-az-backup
```
