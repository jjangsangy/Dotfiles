if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
  fastfetch
end

test -x $HOME/miniconda3/bin/conda
  and eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/opt/google-cloud-sdk/path.fish.inc' ]; . '/usr/opt/google-cloud-sdk/path.fish.inc'; end

if type --quiet z
  zoxide init fish --cmd cd | source
end

if type --quiet starship
  function starship_transient_prompt_func
    starship module character
  end
  function starship_transient_rprompt_func
    starship module time
  end
  starship init fish | source
  enable_transience
end
