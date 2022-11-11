#! /bin/bash
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
then
   echo "Arguments required: $0 [STORAGEACCOUNT] [SASTOKEN] [FILENAME] [FILESHARE]";
   exit 1
else
    STORAGEACCOUNT="$1"
    SASTOKEN="$2"
    FILENAME="$3"
    FILESHARE="$4"
    FILESIZE=$(stat -c%s "dump.sql.gz")
    FILEMD5=$(cat dump.sql.gz | openssl dgst -md5 -binary | openssl enc -base64)
    FILEDATE=$(date -u)
    RESTAPIVERSION=2018-11-09


    echo "==========================="
    echo "FileName: $FILENAME"
    echo "FileSize: $FILESIZE"
    echo "FileMd5: $FILEMD5"
    echo "FileDate: $FILEDATE"
    echo "==========================="

    # Create the file object
    # curl -X PUT -H "x-ms-content-md5: $FILEMD5" -H "Content-Length: 0" -H "x-ms-date: $FILEDATE" -H "x-ms-version: $RESTAPIVERSION" -H "x-ms-content-length: $FILESIZE" -H "x-ms-type: file" "https://$STORAGEACCOUNT.blob.core.windows.net/$FILESHARE/$FILENAME$SASTOKEN"

    #  We need to break the file into seperate parts if FileSize > 4MB
    split -b 100m -a 10 "dump.sql.gz" part

    XML='<?xml version="1.0" encoding="utf-8"?><BlockList>'
    # Upload each part of the file by performing multiple Put Range operations 
    FILEPOINTER=0
    for PARTNAME in $(ls part*);
    do
        PARTSIZE=$(stat -c%s "$PARTNAME")
        PARTMD5=$(cat $PARTNAME | openssl dgst -md5 -binary | openssl enc -base64)
        PARTDATE=$(date -u)
        FILERANGE="bytes=$FILEPOINTER-$(($FILEPOINTER + ($PARTSIZE-1)))"
        echo "--------------------------"
        echo "PartName: $PARTNAME"
        echo "PartSize: $PARTSIZE"
        echo "PartMd5: $PARTMD5"
        echo "PartDate: $PARTDATE"
        echo "FileRange: $FILERANGE"
        echo "Current Filepointer: $FILEPOINTER"

        ENCODED_I="$(echo ${PARTNAME} | openssl enc -base64)"
        BLOCK_ID_STRING="&comp=block&blockid=${ENCODED_I}"
        XML="${XML}<Uncommitted>${ENCODED_I}</Uncommitted>"

        # curl -T ./{$PARTNAME} -H "Content-MD5: $PARTMD5" -H "x-ms-write: update" -H "x-ms-date: $PARTDATE"  -H "x-ms-version: $RESTAPIVERSION" -H "x-ms-range: $FILERANGE" -H "Content-Type: application/octet-stream" "https://$STORAGEACCOUNT.file.core.windows.net/$FILESHARE/$FILENAME$SASTOKEN&comp=range"
        curl -i -X PUT -T ./{$PARTNAME} -H "Content-Type: application/octet-stream" -H "x-ms-date: ${PARTDATE}" -H "x-ms-version: ${RESTAPIVERSION}" -H "x-ms-blob-type: BlockBlob" "https://${STORAGEACCOUNT}.blob.core.windows.net/${FILESHARE}/${FILENAME}${SASTOKEN}${BLOCK_ID_STRING}"
        FILEPOINTER=$(($FILEPOINTER + $PARTSIZE))
        echo "Next Filepointer: $FILEPOINTER"
        echo "--------------------------"
    done;
    XML="${XML}</BlockList>"
    LENGTH=${#XML}
    echo "All blocks shuld be put. Now attempting PutBlockList..."

    BLOCK_ID_STRING="&comp=blocklist"
    curl -i -X PUT -H "x-ms-date: ${PARTDATE}" -H "x-ms-version: ${RESTAPIVERSION}" -H "Content-Length: ${LENGTH}" -d "${XML}" "https://${STORAGEACCOUNT}.blob.core.windows.net/${FILESHARE}/${FILENAME}${SASTOKEN}${BLOCK_ID_STRING}"
    echo "Block List committed"
fi