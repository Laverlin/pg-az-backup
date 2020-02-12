#! /bin/sh

# exit if a command fails
set -e

#apk update
#apk --no-cache add openssl wget
#update-ca-certificates

# install azure cli
apk update
apk upgrade
apk add bash make py-pip
apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python2-dev
pip install azure-cli
apk del --purge build

# install go-cron
apk add curl
curl -SL https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz | zcat > /usr/local/bin/go-cron
#curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron

# cleanup
rm -rf /var/cache/apk/*