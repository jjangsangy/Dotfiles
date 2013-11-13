#!/bin/bash
# Multi-core one liner that parses the current folder for Operator Initials.
# Output is a list of dies run on pin

pinOp="${1}"
find . -name '*.csv' -type f -exec awk -F "," '/%Operaror/ && /'${pinOp}'/ {print FILENAME}' {} \; | parallel -j8 echo {/.}
