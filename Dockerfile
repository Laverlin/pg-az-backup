FROM postgres:alpine
LABEL author="ilaverlin@gmail.com"
LABEL inspired-by="https://github.com/Elexy/postgres-docker-tools, Alex Knol <alexknol@gmail.com>"


RUN apk update && apk upgrade && \
    apk add --no-cache curl

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

COPY ["run.sh", "backup.sh", "restore.sh", "./"]

CMD ["bash", "run.sh"]