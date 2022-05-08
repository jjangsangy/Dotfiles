if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
  fastfetch --load-config all
end

test -x $HOME/miniconda3/bin/conda
  and eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source

