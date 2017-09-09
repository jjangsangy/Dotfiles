#!/usr/bin/env bash

set -euf -o pipefail

# Provide your main network interface which is usually en0
# Pass in the value of the network interfave to spoof
declare IFACE="${1:-en0}"
declare AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36"
declare OLDMAC=$(ifconfig "${IFACE}" ether | awk '/ether/{ if($1=="ether") print $2 }')

# Parameterized Curl Wrapper Function
function _curl () {
    local method=${1:-GET}
    shift
    cat <<- _EOF | curl --config '-' "$@"
        silent
        include
        location
        connect-timeout = 3
        interface = "${IFACE}"
        user-agent = "${AGENT}"
        referer = ";auto"
	_EOF
    if [ $? != 0 ]; then
        echo "Connection Timed Out" > /dev/stderr
        exit
    fi
}

# Generates a 6 Digit Psudo Random MAC Address
function random_mac () {
    local rng="$(openssl rand -hex 6)"
    {
        for i in {0..5}; do printf "${rng:$i:2}:"; done
    } | sed 's/:$//'
}

# Spoof Your MAC before we make a network call
function spoof () {
    local mac_val="${1:-$OLDMAC}"
    local error_str="no physical ethernet on $IFACE"

    printf "\nSetting MAC: %s Value: %s\n" "$OLDMAC" "$mac_val" | grep --color=always --regexp '\([A-z0-9]\+:\)\+[A-z0-9][A-z0-9]'

    sudo ifconfig "${IFACE}" ether "${mac_val:?$error_str}"
}

function get_apmac () {
    local macname=${1:-apname}
    local output=$(_curl GET 'http://google.com')

    if [ "true" = "$(awk '/name="apname"/{ printf "true" }' <<< "$output")" ]; then
        local redirect_url=$(awk '/^Location/{print $2}' <<< "$output")
        local $(tr '\&' ' ' <<< "${redirect_url##*\?}")
        echo "${!macname}"

    else
        echo "You are already connected to the internet" > /dev/stderr
        exit
    fi
}

function main () {
    local clmac=$(random_mac)
    local apname=$(get_apmac apname)

    # Spoof Your MAC
    spoof "$clmac"

    # Authenticate
    _curl POST \
        --form-string apname=$apname \
        --form-string clmac=$clmac \
        --url 'http://sbux-portal.appspot.com/submit'

    # Reset MAC
    spoof $OLDMAC
}

trap spoof EXIT


if [ ${BASH_SOURCE} = "$0" ]; then
    main
fi
