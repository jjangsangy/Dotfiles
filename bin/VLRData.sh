#!/usr/bin/env bash

VLR="/Volumes/vlr/HistoricalWaferDataLogs/PM3"
BACKUP="/Volumes/PubStore/VLR Recipes and historical files backup/VLR2"
DATE_BACKUP="${BACKUP}/$(date "+%m-%d-%Y")"

function mount_drive() {
    local NETBIOS=${1}
    local SHARE=${2}
    local CREDENTIALS=${3-"autoprober:autoprober"}
    local MOUNT_PATH="/${BASEDIR:-"Volumes"}/${SHARE}"

    printf "Mounting drive %16s at %s\n" "${SHARE}" "${MOUNT_PATH}"

    mkdir "${MOUNT_PATH}" &>/dev/null

    mount_smbfs //"${CREDENTIALS}"@"${NETBIOS}"/"${SHARE/' '/%20}" "${MOUNT_PATH}"
}

function main() {

    if [ -d "$VLR" ] && [ -d "$BACKUP" ]; then
       if ! [ -d "${DATE_BACKUP}" ]; then
           mkdir "${DATE_BACKUP}"
       fi

       cp -iprv "$VLR" "$DATE_BACKUP"

    fi
}


if [ $0 = $BASH_SOURCE ]; then
  mount_drive 'columba.calient.local' 'Public'
fi
