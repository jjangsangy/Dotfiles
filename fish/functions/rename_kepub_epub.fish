function rename_kepub_epub
  for i in *.kepub.epub
    echo rename $i
    mv $i (string split -m 1 . $i | head -n 1).kepub
  end
end
