#! /bin/sh
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$3" ]
then
   echo "Arguments required: $0 [STORAGEACCOUNT] [SASTOKEN] [FILENAME] [FILESHARE]";
   exit 1
else
    STORAGEACCOUNT="$1"
    SASTOKEN="$2"
    FILENAME="$3"
    FILESHARE="$4"
    FILESIZE=$(stat -c%s "$FILENAME")
    FILEMD5=$(cat $FILENAME | openssl dgst -md5 -binary | openssl enc -base64)
    FILEDATE=$(date -u)
    RESTAPIVERSION=2018-11-09


    echo "==========================="
    echo "FileName: $FILENAME"
    echo "FileSize: $FILESIZE"
    echo "FileMd5: $FILEMD5"
    echo "FileDate: $FILEDATE"
    echo "==========================="

    # Create the file object
    curl -X PUT -H "x-ms-content-md5: $FILEMD5" -H "Content-Length: 0" -H "x-ms-date: $FILEDATE"  -H "x-ms-version: $RESTAPIVERSION" -H "x-ms-content-length: $FILESIZE" -H "x-ms-type: file" "https://$STORAGEACCOUNT.file.core.windows.net/$FILESHARE/$FILENAME?$SASTOKEN"

    #  We need to break the file into seperate parts if FileSize > 4MB
    split -b 4m --numeric-suffixes --suffix-length=10 $FILENAME part

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
        curl -T ./{$PARTNAME} -H "Content-MD5: $PARTMD5" -H "x-ms-write: update" -H "x-ms-date: $PARTDATE"  -H "x-ms-version: $RESTAPIVERSION" -H "x-ms-range: $FILERANGE" -H "Content-Type: application/octet-stream" "https://$STORAGEACCOUNT.file.core.windows.net/$FILESHARE/$FILENAME?comp=range&$SASTOKEN"
        FILEPOINTER=$(($FILEPOINTER + $PARTSIZE))
        echo "Next Filepointer: $FILEPOINTER"
        echo "--------------------------"
    done;
fi