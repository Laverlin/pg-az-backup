FROM postgres:alpine
LABEL based-on="https://github.com/Elexy/postgres-docker-tools/tree/master/pg-backup-restore-azure, Alex Knol <alexknol@gmail.com>"
LABEL author="ilaverlin@gmail.com"

RUN apk update && apk upgrade && \
    apk add --no-cache bash python3 && \
    apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make && \
    pip3 --no-cache-dir install -U pip && \
    pip3 --no-cache-dir install azure-cli && \
    apk del --purge build

ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV POSTGRES_DATABASE **None**
ENV POSTGRES_EXTRA_OPTS ''

ENV AZURE_STORAGE_ACCOUNT **None**
ENV AZURE_STORAGE_KEY **None**
ENV AZURE_CONTAINER_NAME **None**
ENV AZURE_BLOB_NAME **None**

ENV SCHEDULE **None**

COPY ["run.sh", "backup.sh", "restore.sh", "./"]

CMD ["bash", "run.sh"]