vim.cmd([[
    " - Autocommand Groups {{{
    " ==========================================================
    "   Jump to last cursor position unless it's invalid or an event handler {{{
    augroup readpos
      autocmd!
      autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
      autocmd WinNew      * :wincmd L
    augroup END
    "   }}}

    "   Filetype Configuration {{{
    augroup ftconfig
      autocmd!
      autocmd FileType Makefile  setlocal noet
      autocmd FileType vim       setlocal fdm=marker shiftwidth=2
      autocmd FileType sshconfig setlocal noexpandtab
      autocmd FileType fish      setlocal shiftwidth=2
      autocmd FileType python    setlocal omnifunc=v:lua.vim.lsp.omnifunc
    augroup END

    "   }}}

    "   Microsoft Yank {{{
    if system('uname -r') =~ "Microsoft"
        augroup Yank
            autocmd!
            autocmd TextYankPost * :call system('/mnt/c/windows/system32/clip.exe ',@")
        augroup END

        autocmd VimLeave * set guicursor=a:ver25blinkon100
    endif
    "   }}}

    " }}}
]])

