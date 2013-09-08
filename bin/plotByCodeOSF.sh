#!/bin/bash
clear
#  
#  Calient Technologies
#  Created by Sang Han

#Initialize Variables & Functions
WaferID=${1}
locID=${2}
pubDir=/Volumes/PubStore
filePath=${pubDir}/_Production\ Data/MEMs\ PROBE\ DATA/OSF/${WaferID}/${WaferID}\ ${locID}.csv 

mountCalient ()
{
mount -t smbfs -o soft //visual:visual@sbnetapp/PubStore ${pubDir}
}

if ! [[ $# -eq 2 ]] ; then
    echo "Please enter Wafer, Row/Column"
    read WaferID locID
fi

if ! [[ -d "${pubDir}" ]] ; then
    echo "Directory does not exist, creating directory and mounting drive"
    mkdir ${pubDir} && mountCalient || rmdir ${pubDir}
fi

declare -A binArray=( [100]="Full Deflection" \
    [101]="Shorted" \
    [102]="Over Current" \
    [103]="No Deflection" \
    [104]="Bad Initial Angle" \
    [105]="Off Azimuth" \
    [106]="V Limit Poor Deflect" \
    [107]="M Limit Poor Deflect" \
    [108]="V Limit Full Deflect" \
    [109]="M Limit Full Deflect" )

declare -A driveArray=( ["A"]=1 \
    ["B"]=3 \
    ["C"]=2 \
    ["D"]=4 )

printf "Specify binning for %s %s Wafer\n" ${WaferID} ${locID}
read -a binID

mapfile -t binningTable < <(tail -n 397 "${filePath}" | head -n 385 | cat -v | cut -f 1-3 -d ',' | sed 's:\^M::g')
mapfile -t arrayTable< <(cat -v "${filePath}" | head -n 1560 | tail -n 1528 | sed 's:\^M::g' | cut -f 2-3,7 -d ',' | sort -g)

rm /tmp/binning*.csv

for ((i=0; i<${#arrayTable[@]}; i=i+4 )); do printf "%s\n" "${arrayTable[i]}" >> /tmp/binningA.csv; done
for ((i=1; i<${#arrayTable[@]}; i=i+4 )); do printf "%s\n" "${arrayTable[i]}" >> /tmp/binningB.csv; done
for ((i=2; i<${#arrayTable[@]}; i=i+4 )); do printf "%s\n" "${arrayTable[i]}" >> /tmp/binningC.csv; done
for ((i=3; i<${#arrayTable[@]}; i=i+4 )); do printf "%s\n" "${arrayTable[i]}" >> /tmp/binningD.csv; done

mapfile -t binningAArray < <(cut -f 2 -d ',' /tmp/binningA.csv)
mapfile -t binningBArray < <(cut -f 2 -d ',' /tmp/binningB.csv)
mapfile -t binningCArray < <(cut -f 2 -d ',' /tmp/binningC.csv)
mapfile -t binningDArray < <(cut -f 2 -d ',' /tmp/binningD.csv)

for ((i=0;i<${#binningAArray[@]}; i++)); do echo ${driveArray[${binningAArray[i]}]} >> /tmp/binningAArray.csv; done
for ((i=0;i<${#binningBArray[@]}; i++)); do echo ${driveArray[${binningBArray[i]}]} >> /tmp/binningBArray.csv; done
for ((i=0;i<${#binningCArray[@]}; i++)); do echo ${driveArray[${binningCArray[i]}]} >> /tmp/binningCArray.csv; done
for ((i=0;i<${#binningDArray[@]}; i++)); do echo ${driveArray[${binningDArray[i]}]} >> /tmp/binningDArray.csv; done


paste -d ',' /tmp/binningA.csv /tmp/binningAArray.csv \
    /tmp/binningB.csv /tmp/binningBArray.csv \
    /tmp/binningC.csv /tmp/binningCArray.csv \
    /tmp/binningD.csv /tmp/binningDArray.csv | cut -f 1,3-4,7-8,11-12,15-16 -d ',' > /tmp/binningABCD.csv

printf "%s\n" "${binningTable[@]}" > /tmp/binningTable.csv

printf "%03d\n" $(cut -f 1 -d ',' /tmp/binningTable.csv) > /tmp/binningMirror.csv
cat /tmp/binningTable.csv | cut -f 2 -d ',' > /tmp/binningCode.csv
cat /tmp/binningTable.csv | cut -f 3 -d ',' > /tmp/binningDisposition.csv

paste -d ',' /tmp/binningMirror.csv /tmp/binningCode.csv /tmp/binningDisposition.csv | sed '/Untested/d' > /tmp/binning.csv
paste -d ',' binningABCD.csv <(cat binning.csv | cut -f 3 -d ',') > binning2.csv


for ((i=0; i<${#binID[@]}; i++)); do grep "${binArray[${binID[i]}]}" /tmp/binning2.csv >> /tmp/binningGrep.csv; done
(printf "Mirror,Disposition,Electrode,Disposition,Electrode,Disposition,Electrode,Disposition,Electrode,DispositionCode\n" && sort -g /tmp/binningGrep.csv) > binning.csv

open /tmp/binning.csv
