# Checks for marks directory, and creates it
export MARKPATH=$HOME/.marks
if ! [[ -d "$MARKPATH" ]]; then
    echo "No directory at $MARKPATH"
    echo "Directory being created"
    mkdir -p "$MARKPATH"
fi


jump() {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

mark() {
    local MARKING="$MARKPATH/$1"
    ln -s "$(pwd)" "$MARKING" || \
        printf "Could not symlink %s to %s" "$(pwd)" "$MARKING"
}

unmark() {
    rm -i "$MARKPATH/$1"
}

marks() {
    ls -l $MARKPATH | sed -e 's:\  : :g' -e 's:@::g' | cut -f 9- -d ' ' | \
    awk \
        'BEGIN {FS="->"}; NR>1 {printf("%-3.2d %-24s %s %s\n",NR-1,$1,"->",$2)}'
}

_completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist=$(find ~/.marks -type l -print | rev | cut -f 1 -d '/' | rev)
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
}

complete -F _completemarks jump unmark

