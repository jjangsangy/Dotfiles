#!/bin/bash
# Awk script that parses for dates.
# Not advised to be used over network

# TODO: Merge into main pin script. Parameterize with
# getopts.
pinDate="${1}"
pinMonth=$(cut -d "/" -f1 <(echo "${pinDate}"))
find . -name '*.csv' -type f -print0 | xargs -0 awk -F "," '\
    /%Start Date/ && /11\/12\/2013/ {\
        print FILENAME\
    }' \
    | sort
