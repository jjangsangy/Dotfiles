#!/bin/sh

#  
#

visualCred="visual:visual"
autoproberCred="autoprober:autoprober"
function calient_smb () {

if ! [ -d "/Volumes/${2}" ] ; then
    echo "Creating Directory"
    mkdir /Volumes/"${2}"
    mount -t smbfs -o soft //"${3}"@"${1}"/"${2/' '/%20}" "/Volumes/${2}" || rmdir /Volumes/"${2}"
else
    mount -t smbfs -o soft //"${3}"@"${1}"/"${2/' '/%20}" "/Volumes/${2}" || rmdir /Volumes/"${2}"
fi 
}

## MountPoints ###########
#[COLUMBA PUBLIC]
calient_smb columba Public ${visualCred} &

#[SBNETAPP PUBSTORE]
calient_smb sbnetapp PubStore ${visualCred} &

#[COLUMBA OPTICAL COMP]
calient_smb columba Optical\ Comp ${visualCred} &


wait
