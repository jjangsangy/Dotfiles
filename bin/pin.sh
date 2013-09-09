#!/bin/sh
clear

#Initialize Variables & Functions
WaferID=${1}
locID=${2}
pubDir=/Volumes/PubStore
filePath=${pubDir}/_Production\ Data/MEMs\ PROBE\ DATA/OSF

pinGrepHead ()
    {
        grep -E "%Mirror ID:|%Operaror:|%Comment:|%Start Date:"
    }

pinGrepTail ()
    {
        grep -E "101 - Shorted|102 - Over Current|103 - No Deflection|105 - Off Azimuth|104 - Bad Initial Angle|106 - V Limit Poor Deflect|107 - M Limit Poor Deflect|108 - V Limit Full Deflect|109 - M Limit Full Deflect|100 - Full Def"
    }

mountCalient ()
    {
        mount -t smbfs -o soft //visual:visual@sbnetapp/PubStore ${pubDir}
    }

if [[ $# -eq 1 ]] ; then locID="R*C*"

elif [[ $# -eq 0 ]] || [[ $# -gt 2 ]] ; then
    echo "Please enter Wafer and Row/Column"
    read WaferID locID
fi

if ! [[ -d "${pubDir}" ]] ; then
    echo "Directory does not exist, creating directory and mounting drive"
    mkdir ${pubDir} && mountCalient || rmdir ${pubDir}

elif ! [[ -d  "${filePath}" ]] ; then
    echo "Drive is not mounted"
    echo "Mounting Drive"
    mountCalient
fi

#If directory to the data is found, program will grep the yield, else quit.
if [[ -d "${filePath}/${WaferID}" ]] ; then

    IFS=$'\n'
    pArray=(`ls -1 ${filePath}/${WaferID}/${WaferID}\ ${locID}.csv | sed 's/*//g'`)
    pinCount=${#pArray[@]}

    [[ -f "/tmp/${WaferID}_yield2.csv" ]] && rm /tmp/${WaferID}_yield2.csv
    [[ -f "/tmp/${WaferID}_die2.csv" ]] && rm /tmp/${WaferID}_die2.csv

# Iterate through array elements and catenate results.
    printf "We have found %d dies\n" ${pinCount} 
    for i in "${pArray[@]}";
    do
        echo ${i} | rev | cut -d '/' -f -1 | rev | cut -d '.' -f 1
        head ${i} | pinGrepHead | cut -d ',' -f 1-2 >> /tmp/${WaferID}_yield2.csv
        tail ${i} | pinGrepTail | cut -d ',' -f 1-2 >> /tmp/${WaferID}_yield2.csv
    done
echo "DONE!"
sleep 2

clear

#Display output in pager and open yield result in excel
open /tmp/${WaferID}_yield2.csv

else
    echo "Wafer does not exist"

    return 0
fi
