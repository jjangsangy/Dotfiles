#!/bin/bash

Autoprober="autoprober:autoprober"

function CalSMB () {
if ! [[ -d /Volumes/"${2}" ]]; then
    echo "Mounting drive ${2}"
    mkdir /Volumes/"${2}" && mount -t smbfs -o soft //"${3}"@"${1}"/"${2/' '/%20}" /Volumes/"${2}" && echo "Mounting drive ${2} complete"
else
    echo "Drive ${2} already exists, unmounting"
    rmdir /Volumes/"${2}" || umount /Volumes/"${2}"
    echo "Mounting drive ${2}"
    mkdir /Volumes/"${2}" && mount -t smbfs -o soft //"${3}"@"${1}"/"${2/' '/%20}" /Volumes/"${2}" && echo "Mounting drive ${2} complete"
fi
}

## MountPoints ###########
#[COLUMBA PUBLIC]
CalSMB columba Public ${Autoprober} &

#[SBNETAPP PUBSTORE]
CalSMB sbnetapp PubStore ${Autoprober} &

#[COLUMBA OPTICAL COMP]
CalSMB columba Optical\ Comp ${Autoprober} &

wait
