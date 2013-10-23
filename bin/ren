#!/bin/sh

#Renames the file in current directory

sArray=(`ls -1 | sed -e 's|/||g' -e 's|*||g' | sed -n '/^[A-Z]/p' | sed -n '/[0-9]/p' | sed '/-/ d'`)
pArray=(`ls -1 | sed -e 's|/||g' -e 's|*||g' | sed -n '/^[A-Z]/p' | sed -n '/[0-9]/p' | sed '/-/ d' | sed 's/[A-Z]*/&-/'`)

if [[ ${#sArray[@]} -eq ${#pArray[@]} ]]; then
    
    printf "sArray has %d elements\n" ${#sArray[@]}
    printf "pArray has %d elements\n" ${#pArray[@]}
    
    for (( i=0; i<${#sArray[@]}; i++ ))
    do
        printf "%s renamed to %s\n" ${sArray[i]} ${pArray[i]}
    done
    
    echo "Would you like to continue?"
    read Resp

    if [[ ${Resp} == "Yes" ]]; then
        for (( i=0; i<${#sArray[@]}; i++ ))
        do
            mv ${sArray[i]} ${pArray[i]}
        done
        echo "Done!"
    else
        echo "Stopped"
    fi

else
    echo "Array mismatch" 
    printf "sArray has %d elements\n" ${#sArray[@]}
    printf "pArray has %d elements\n" ${#pArray[@]}
fi
