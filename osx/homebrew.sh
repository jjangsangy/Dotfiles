#!/usr/bin/env bash
#================================================================================
usage() { cat <<- INSTRUCTIONS

          FILE: homebrew.sh

   DESCRIPTION: Some utilities and shell scripts for working with the homebrew
                package manager.
       OPTIONS: [-h help] [-t test] [-i install]

        AUTHOR: Sang Han


	INSTRUCTIONS
}

PROGNAME=$(basename "${BASH_SOURCE}")
PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

installer() {
    if [ ! $(which brew) ]; then
        echo "Installing Homebrew"
        ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
    fi
}

main() {
# ===============================================================================
# ===============================================================================
    return
}

# ===============================================================================
# Parse Options
# ===============================================================================
declare -i TEST=0
while getopts ":hit" options; do
    case ${options} in
        h) usage
           exit 0
            ;;
        i) installer
           exit 0
           ;;
        t) TEST=1
           ;;
        \?)
            echo "Invalid options: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done
    shift $((OPTIND-1))


if [ $0 = ${BASH_SOURCE[0]} ]; then
    main
fi
