set -gx EDITOR nvim

function fish_greeting
    if type --quiet fastfetch
        fastfetch
    end
end

if type --quiet zoxide
    zoxide init fish --cmd cd | source
end

if type --quiet uv
    uv generate-shell-completion fish | source
end

if type --quiet ruff
    ruff generate-shell-completion fish | source
end

if type --quiet starship
    set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"

    function starship_transient_prompt_func
        starship module character
    end
    function starship_transient_rprompt_func
        starship module time
    end

    starship init fish | source

    enable_transience
end

abbr --add vim nvim
abbr --add g git
abbr --add r 'rsync -av --progress'
abbr --add .. 'cd ..'
abbr --add ... 'cd ../..'
abbr --add .... 'cd ../../..'
abbr --add ..... 'cd ../../../..'
abbr --add ...... 'cd ../../../../..'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/opt/google-cloud-sdk/path.fish.inc' ]
    . '/usr/opt/google-cloud-sdk/path.fish.inc'
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/miniconda3/bin/conda
    eval ~/miniconda3/bin/conda "shell.fish" hook $argv | source
else
    if test -f ~/"miniconda3/etc/fish/conf.d/conda.fish"
        . ~/"miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH ~/"miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<
