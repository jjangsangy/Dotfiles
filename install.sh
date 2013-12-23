#!/bin/bash
#
# FILE:         install
# AUTHOR:       Sang Han
# VERSION:      1.0.0rc
# DESCRIPTION   Install utility for dotfile configs
# DEPENDS:      Dotfiles

DOTFILES="$(dirname ${BASH_SOURCE[0]})"

usage() {
    cat <<- DOCUMENT
    $(basename $0) [-h help]

    Install utility for dotfile configs

    AUTHOR:     Sang Han
    YEAR:       2013
    VERSION:    1.0.0rc

    -h [help]
        Outputs usage directions
    -t [test]
        Runs unit tests

DOCUMENT
    exit 0
}

check_os() {
    # Initialize indexed array for storing config files
    declare -a bash_files base_files
    if [[ $(uname -s) =~ "Darwin" ]]; then
        install_osx
    elif [[ $(uname -s) =~ "Linux" ]]; then
        install_linux
    elif [[ $(uname -s) =~ "CYGWIN" ]]; then
        install_cyg
    else
        printf "Your operating system is not supported\n" >&2
        exit 1
    fi
}

install_linux() {
    return
}

install_cyg() {
    return
}

test_names() {
    printf "\$TEST is %s\n" ${TEST}
    printf "\$DOTFILES is %s\n" "${DOTFILES}"
}

test_install() {
    bash_files=(\
                 profile \
                 jump.sh \
                 prompt.sh \
                 dircolors \
                 dircolors_dark \
                 dircolors_light\
                 )

    for (( i=0; i<${#bash_config[@]}; i++ )); do
        printf "%s and %s\n" "${bash_config[i]}" "${bash_config[i]/#/$HOME/.}"
    done
}

install_osx() {
    # Files for OSX install
    bash_files=(\
                 profile \
                 jump.sh \
                 prompt.sh \
                 dircolors \
                 dircolors_dark \
                 dircolors_light\
                 )

    for (( i=0; i<${#bash_config[@]}; i++ )); do
        printf "%s and %s\n" "${bash_config[i]}" "${bash_config[i]/#/$HOME/.}"
    done
}

# Parse Options
declare -i TEST=0
while getopts ":h" OPTION; do
    case ${OPTION} in
        h) usage
            ;;
        t) TEST=1
            ;;
        ?) echo "Invalid option: -${OPTARG}" >&2
           exit 1
            ;;
    esac
done
    shift $(($OPTIND-1))
main() {
    if (($TEST==1)); then
        test_names
    fi
    check_os
}

if [[ "$0" == ${BASH_SOURCE} ]]; then
    main
fi
