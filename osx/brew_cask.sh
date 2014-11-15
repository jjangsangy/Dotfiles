#!/usr/bin/env bash
# ==============================================================================
usage () { cat <<- DOCUMENT

    AUTHOR:      Sang Han

    This is a small shell script that automatically installs a list
    of software using brew cask. If homebrew is not already installed
    use the homebrew tool to install. To install brew cask, run this
    with -i flag.

    This is a slightly-opinionated personal favorite list of software.
    In the future this may include other resources,
    but will always be tailored to developers and power users.

    USAGE:

        brew_cask.sh [-i] [-h] [-l] [-a] \$cask_set

    OPTIONAL ARGUMENTS:

        [-h]: Prints out this help message and exit
        [-i]: Installs brew cask and exit
        [-l]: List out all packages sets and enclosing applications and exit
        [-a]: Install everything

    CASK SETS:

	DOCUMENT

    printout "\t- " "${cask_set[@]}"

    return 0
}

unset HOMEBREW_VERBOSE

# ===============================================================================
# Headers
# ===============================================================================
readonly cask_set=(
    'adobe'
    'fonts'
    'general'
    'programming'
    'osx_quicklook'
)

function packages() {

    # Define sets of packages here and in the header region
    # to add it to the list of available sets
    local -a general=(
        'adobe-reader'
        'dropbox'
        'evernote'
        'firefox'
        'google-chrome'
        'google-drive'
        'spectacle'
        'the-unarchiver'
        'transmission'
        'vlc'
    )
    local -a fonts=(
        'font-anonymous-pro'
        'font-cutive'
        'font-cutive-mono'
        'font-dejavu-sans'
        'font-droid-serif'
        'font-droid-sans'
        'font-droid-sans-mono'
        'font-fira-sans'
        'font-inconsolata-dz'
        'font-novamono'
        'font-oxygen'
        'font-oxygen-mono'
        'font-source-code-pro'
        'font-ubuntu'
    )
    local -a programming=(
        'alfred'
        'airmail'
        'dash'
        'base'
        'github'
        'boot2docker'
        'imageoptim'
        'iterm2'
        'macvim'
        'sequel-pro'
        'vagrant'
        'virtualbox'
        'handbrake'
        'haroopad'
    )
    local -a adobe=(
        'adobe-creative-cloud'
        'adobe-photoshop-lightroom'
    )
    local -a osx_quicklook=(
        'betterzipql'
        'qlcolorcode'
        'qlmarkdown'
        'qlprettypatch'
        'qlstephen'
        'quicklook-csv'
        'quicklook-json'
        'suspicious-package'
        'webp-quicklook'
    )

    # Printout
    for set in "${cask_set[@]}"; do
    {
        # Indirect Reference
        declare -a pkg=$set"[@]"

        printf "[ %s ]\n" "$set"
        printout "- " "${!pkg}"
    }
    done

}

# ===========================================================================
# Printout Package Lists
# ===========================================================================
function printout() {
    local fmt="$1" && shift && local array=($@)

    for block in "${array[@]}"; do
    {
        printf "%b%s\n" "$fmt" "$block"
    }
    done
    printf "\n"

    return 0
}

# ===========================================================================
# Brew Cask Installer
# ===========================================================================
function install_cask() {

    # Get the Latest Version
    brew update
    brew upgrade

    # Install
    brew install caskroom/cask/brew-cask

    # Post Install
    brew cask install xquartz
    brew cask install alfred

    # Brew Taps
    brew tap caskroom/fonts
    brew cask alfred link
}


function check_cask()
{
    # Ensure Cask is Installed
    local msg="brew cask not installed, installing"

    if type -P brew cask > /dev/null; then
        echo "$msg" && install_cask
    fi

    return 0
}

# ===========================================================================
# Package Installer
# ===========================================================================
function install()
{
    local -a apps=($@) && declare -i i=0

    while [ ${apps[i]} ]; do
    {
        printf "Installing %25.25s:\n" "${apps[i]}"
        if brew cask install ${apps[i++]} 2>/dev/null; then
            printf "Success\n\n"
        else
            printf "Fail\n\n"
        fi
    }
    done

    # Cleanup
    brew cask cleanup
}

# ===========================================================================
# Main
# ===========================================================================
function main()
{
    eval "$(declare -f packages | grep "local -a")"
    declare -a pkg selection=($@)

    # Install all valid sets that are defined
    for apps in "${selection[@]}"; do
    {
        # Input Validation
        for set in "${cask_set[@]}"; do
        {
            if [ "$apps" = "$set" ]; then
                pkg=${apps}'[@]' && install "${!pkg}"
            fi
        }
        done
    }
    done

    return 0
}

# ===============================================================================
# Option Parser
# ===============================================================================
while getopts ":liha" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
           ;;
        i) install_cask
           exit 0
           ;;
        l) packages
           exit 0
           ;;
        a) main "${cask_set[@]}"
           exit 0
           ;;
       \?) echo "Invalid option: -${OPTARG}" >&2
           exit 1
           ;;
    esac
done
    shift $((OPTIND-1))

# ===============================================================================
# Entry Point
# ===============================================================================
if [ "$0" = "${BASH_SOURCE}" ]; then
    check_cask && main "$@"
fi
