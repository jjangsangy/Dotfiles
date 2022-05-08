function rips_capitalize
  for i in $argv
    set -l caps (string trim -r -c/ $i | string split '_' | tail -n +2 | string join ' ' | sed -e 's/[^ _-]*/\u&/g' -e 's/ \+/ /g' | string trim)
    echo $caps
    mv $i $caps
  end
end
