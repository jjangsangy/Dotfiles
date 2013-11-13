#! /bin/bash

mapfile -t QArray < <(find . -type f -name "*Meas Defl Summary.txt")
for (( i=0; i<${#QArray[@]}; i++ )); do awk -v count=0 'BEGIN { OFS="," }; { sub("\r$", "") }; !/Validity/ && !/B0??/ && $17 > 10 && $17 < 30 && $6 < 10 { if(length($1) != 0) print $1,$2,$5,$6,$17; count++ }; NR==1 { print $1,$5,$6 }; NR==2 { printf "Device,Electrode,Voltage,Defl,Q\n" }; END { printf "Good Measurements,%d\n\n", count }' "${QArray[i]}"; done | tee ~/Desktop/QValid.csv | egrep "%|Good Measurements" | tee ~/Desktop/Q.csv | grep -B 1 "Good Measurements,0" > ~/Desktop/NoQ.csv

mapfile -t NoQArray < <(awk 'BEGIN { FS = ","; OFS = "," }; { if($3!="") print $2,$3 } ' ~/Desktop/NoQ.csv | sed 's/-[0-9]$//g' | uniq)
for (( i=0; i<${#NoQArray[i]}; i++ )); do awk -v sumQ=0 -v QArrayDie=${NoQArray[i]} 'BEGIN { FS = ","; OFS = " "}; /'${NoQArray[i]}'/,/Good Measurement/ { if (length($2) < 3 ) sumQ=$2 } END { if (sumQ < 4) printf("%s\n",QArrayDie) }' /Users/jjangsangy/Desktop/Q.csv ; done | sed 's/,/ /g' > ~/Desktop/BadQ.csv

mapfile -t findArray < <(cat ~/Desktop/BadQ.csv)
for (( i=0; i<${#findArray[@]}; i++ )); do find . -type f \( -name "*Meas Defl Summary.txt" -and -name \*"${findArray[i]}"\* \) -exec cp '{}' ~/Desktop/ \;; done
