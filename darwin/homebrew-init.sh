#!/usr/bin/env bash
usage () { cat <<- DOCUMENT
#===============================================================================
#
#          FILE: $0
#
#         USAGE: $0
#
#   DESCRIPTION: Setup Environment for Homebrew
#
#       OPTIONS: -h (Print Usage)
#                -a (Install all the formulas)
#        AUTHOR: Sang Han (jjangsangy@gmail.com)
#       CREATED: 09/16/2015
#      REVISION: 1.0.0
#===============================================================================
	DOCUMENT
}

function main() {

    # Command Line Tools
    which gcc &>/dev/null || sudo xcode-select --install 2>/dev/null

    # Install Homebrew
    if [ $(type -p brew) != /usr/local/bin/brew ]; then
        install_homebrew
    fi

    if [ $BASH_VERSINFO != 4 ]; then 
        install_bash
    fi

    if [ $(type -p brew-cask) != /usr/local/bin/brew-cask ]; then
        install_cask
    fi
}

function install_cask() {
    brew install caskroom/cask/brew-cask
}

function install_bash() {
    brew install bash && echo "/usr/local/bin/bash" | tee -a /etc/shells
}

function install_homebrew() {
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && install_coreutils

        taplist=($(cat taplist.txt))

        for tap in ${taplist[@]}; do
            brew tap $tap 2>/dev/null
        done
}

function install_coreutils() {

    brew install coreutils 2>/dev/null

    if ! [ -L /usr/local/bin/ls ]; then
        ln -s "$(brew --prefix)/bin/gls" "$(brew --prefix)/bin/ls"
    fi

    if ! [ -L /usr/local/bin/dircolors ]; then
        ln -s "$(brew --prefix)/bin/gdircolors" "$(brew --prefix)/bin/dircolors"
    fi
}

function install_formulas() {

    local formulas=($(cat brewlist.txt))

    for formula in ${formulas[@]}; do
    {
        brew_install $formula
    }
    done
}

function brew_install() {
        local formula="$1"
        local options="$(brew info "${formula}" | grep '^\-\-with-')"

        printf "Installing: %s\n" $formula
        printf "Options: %s\n" $options
        printf "\n"

        brew list ${formula} &>/dev/null && brew reinstall ${formula} ${options} || brew install "${formula}" ${options}
}

unset HOMEBREW_VERBOSE
# ===============================================================================
# Option Parser
# ===============================================================================
while getopts ":ha" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
           ;;
        a) main
           install_formulas
           ;;
       \?) echo "Invalid option: -${OPTARG}" >&2
           usage
           exit 1
           ;;
    esac
done
    shift $((OPTIND-1))

if [ "$0" = "${BASH_SOURCE}" ]; then
    main "$@"
fi
