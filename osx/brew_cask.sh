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

        brew_cask.sh [-i] [-h] cask_set

    CASK SETS:

	DOCUMENT

    # Printout Available Sets
    for set in ${cask_sets[@]}; do
        printf "        %s\n" "$set"
    done
    printf "\n"

    return 0
}


# ===============================================================================
# Option Parser
# ===============================================================================
readonly cask_sets=('adobe' 'fonts' 'general' 'programming' 'osx_quicklook')
while getopts ":ih" OPTION; do
    case ${OPTION} in
        h) usage
           exit 0
           ;;
        i) install_cask
           exit 0
           ;;
       \?) echo "Invalid option: -${OPTARG}" >&2
           exit 1
           ;;
    esac
done
    shift $(($OPTIND-1))


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

# ===========================================================================
# Printout Package Lists
# ===========================================================================
function print_packages() {

    local packages=()
    local apps=($@)

    for app in ${apps[@]}; do
    {
        # Indirection and Array Expansion
        packages=( $(eval echo \${"$app"[@]}) )

        # Loop Through Packages
        printf "[ %s ]\n" "$app"

        for package in ${packages[@]}; do
        {
            printf "%s%s\n" "- " "$package"
        }
        done
        printf "\n"
    }
    done

    return 0
}

# ===========================================================================
# Package Installer
# ===========================================================================
function install() {

    local packages=()
    local apps=($@)

    # Install
    for app in ${apps[@]}; do
    {
        packages=( $(eval echo \${"$app"[@]}) )
        for package in ${packages[@]}; do
        {
            echo "Installing $package"
            brew cask install $package 2> /dev/null
        }
        done
    }
    done

    # Cleanup
    brew cask cleanup
}

# ===========================================================================
# Main
# ===========================================================================
function main() {

    local selection=($@)

    local general=(
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
    local fonts=(
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
    local programming=(
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
    local adobe=(
        'adobe-creative-cloud'
        'adobe-photoshop-lightroom'
    )
    local osx_quicklook=(
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

    # Install all valid sets that are defined
    for apps in ${selection[@]}; do
    {
        for set in ${cask_sets[@]}; do
        {
            # Input Validation
            if [ "$apps" = "$set" ]; then
                install "$apps"
            fi
        }
        done
    }
    done

    return 0
}

# ===============================================================================
# Entry Point
# ===============================================================================
if [ "$0" = "${BASH_SOURCE}" ]; then
    main "$@"
fi
