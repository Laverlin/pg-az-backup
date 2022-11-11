FROM postgres:15-alpine
LABEL author="ilaverlin@gmail.com"
LABEL inspired-by="https://github.com/Elexy/postgres-docker-tools, Alex Knol <alexknol@gmail.com>"

RUN apk update && apk upgrade && \
    apk add --no-cache openssl && \
    apk add --no-cache curl
#     apk add --no-cache postgresql-client && \

# RUN apt-get update && apt install -y postgresql curl

ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV POSTGRES_DATABASE **None**
ENV POSTGRES_EXTRA_OPTS ''

ENV AZURE_STORAGE_ACCOUNT **None**
ENV AZURE_SAS **None**
ENV AZURE_CONTAINER_NAME **None**
ENV AZURE_BLOB_NAME **None**

ENV SCHEDULE **None**
ENV RESTORE **None**

ENV LAST_BACKUP_MARKER last-backup-name

RUN mkdir /app

COPY ["run.sh", "backup.sh", "upload.sh", "restore.sh", "process-vars.sh", "/app"]

CMD ["sh", "/app/run.sh"]