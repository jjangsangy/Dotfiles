##!/bin/bash
#
# FILE:         Solarize
# AUTHOR:       Sang Han
# VERSION:      1.0.0
# DESCRIPTION:  Script for loading Solarize Dark or Light dircolors
# DEPENDS:      GNU Coreutils (dircolors)
#               GNU Coreutils (ls)

# Global ENVAR
export LSCOLORS='--color=auto'

usage() {
    cat <<- EOF
    $(basename $0) [-h help] [-s silent]

    FILE:         Solarize
    AUTHOR:       Sang Han
    VERSION:      1.0.0
    DESCRIPTION:  Script for loading Solarize Dark or Light dircolors
    DEPENDS:      GNU Coreutils (dircolors)
                  GNU Coreutils (ls)

    -h [help]
        Outputs usage info

EOF
    exit 0
}

check_utils() {
    # Check GNU Coreutils
    if [[ -z $(ls --version | grep 'GNU coreutils') ]]; then
        echo "GNU coreutils (ls) is not properly installed" >&2
        exit 1
    fi

    if [[ -z $(dircolors --version | grep 'GNU coreutils') ]]; then
        echo "GNU coreutils (dircolors) is not properly installed" >&2
        exit 1
    fi
}

check_dircolors() {
    # Checks for dircolors file at $HOME
    if [[ -e $HOME/.dircolors ]]; then
        return 0
    else
        echo "No file at $HOME/.dircolors" >&2
        exit 1
    fi
}

check_dark() {
    # Checks dircolors dark
    if [[ -e $HOME/.dircolors_dark ]]; then
        return 0
    else
        echo "No file at $HOME/.dircolors_dark" >&2
        exit 1
    fi
}
check_light() {
    # Checks dircolors light
    if [[ -e $HOME/.dircolors_light ]]; then
        return 0
    else
        echo "No file at $HOME/.dircolors_light" >&2
        exit 1
    fi
}

# Options
while getopts ":hdl" options; do
    case ${options} in
        h|help)
            usage
            ;;
        d|dark)
            DARK=1
            ;;
        l|light)
            LIGHT=1
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done

if [[ "$0" == ${BASH_SOURCE} ]]; then
    check_dircolors
    [[ $DARK = 1 ]] && eval $(dircolors -b $HOME/.dircolors_dark) && echo "DARK"

    [[ $LIGHT = 1 ]] && eval $(dircolors -b $HOME/.dircolors_light) && echo "LIGHT"
fi
