# Checks for marks directory, and creates it
if ! [[ -d $HOME/.marks ]]; then
    echo "No path for jump"
    echo "Directory being created"
    mkdir $HOME/.marks
fi

export MARKPATH=$HOME/.marks

function jump {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

function mark {
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

function unmark {
    rm -i "$MARKPATH/$1"
}

function marks {
    ls -l $MARKPATH | sed -e 's:\  : :g' -e 's:@::g' | cut -f 9- -d ' ' | awk 'BEGIN {FS="->"}; NR>1 {printf("%-3.2d %-24s %s %s\n",NR-1,$1,"->",$2)}'
}

_completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist=$(find ~/.marks -type l -print | rev | cut -f 1 -d '/' | rev)
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
}

complete -F _completemarks jump unmark

