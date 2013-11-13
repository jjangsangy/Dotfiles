#!/bin/bash
#
#  pin_yield.sh
#
#  Calient Technologies
#  Created by Sang Han
#  Parses Pin Prober Data on network drive into working directory

#filePath requires Pubstore to be mounted locally in OS X /Volumes directory

#Initialize Variables & Functions
WaferID=${1}
locID=${2}
pubDir=/Volumes/PubStore
filePath=${pubDir}/_Production\ Data/MEMs\ PROBE\ DATA/OSF

pinGrepHead () {
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


