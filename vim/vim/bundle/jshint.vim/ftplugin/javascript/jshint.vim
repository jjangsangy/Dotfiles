
" Global Options
"
" Enable/Disable highlighting of errors in source.
" Default is Enable
" To disable the highlighting put the line
" let g:JSHintHighlightErrorLine = 0
" in your .vimrc
"
if exists("b:did_jshint_plugin")
    finish
else
    let b:did_jshint_plugin = 1
endif

if has("win32")
	let s:install_dir = '"' . expand("~/vimfiles/ftplugin/javascript") . '"'
else
	let s:install_dir = expand("<sfile>:p:h")
endif

au BufLeave <buffer> call s:JSHintClear()

au BufEnter <buffer> call s:JSHint()
au InsertLeave <buffer> call s:JSHint()
"au InsertEnter <buffer> call s:JSHint()
au BufWritePost <buffer> call s:JSHint()

" due to http://tech.groups.yahoo.com/group/vimdev/message/52115
if(!has("win32") || v:version>702)
	au CursorHold <buffer> call s:JSHint()
	au CursorHoldI <buffer> call s:JSHint()

	au CursorHold <buffer> call s:GetJSHintMessage()
endif

au CursorMoved <buffer> call s:GetJSHintMessage()

if !exists("g:JSHintHighlightErrorLine")
  let g:JSHintHighlightErrorLine = 1
endif

if !exists("*s:JSHintUpdate")
    function s:JSHintUpdate()
        silent call s:JSHint()
        call s:GetJSHintMessage()
    endfunction
endif

if !exists(":JSHintUpdate")
    command JSHintUpdate :call s:JSHintUpdate()
endif

noremap <buffer><silent> dd dd:JSHintUpdate<CR>
noremap <buffer><silent> dw dw:JSHintUpdate<CR>
noremap <buffer><silent> u u:JSHintUpdate<CR>
noremap <buffer><silent> <C-R> <C-R>:JSHintUpdate<CR>

" Set up command and parameters
if has("win32")
  let s:cmd = 'cscript /NoLogo '
  let s:runjshint_ext = 'wsf'
else
  let s:runjshint_ext = 'js'
  if exists("$JS_CMD")
    let s:cmd = "$JS_CMD"
  elseif executable('/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc')
    let s:cmd = '/System/Library/Frameworks/JavaScriptCore.framework/Resources/jsc'
  elseif executable('node')
    let s:cmd = 'node'
  elseif executable('js')
    let s:cmd = 'js'
  else
    echoerr('No JS interpreter found. Checked for jsc, js (spidermonkey), and node')
  endif
endif
let s:plugin_path = s:install_dir . "/jshint/"
let s:cmd = "cd " . s:plugin_path . " && " . s:cmd . " " . s:plugin_path . "runjshint." . s:runjshint_ext

let s:jshintrc_file = expand('~/.jshintrc')
if filereadable(s:jshintrc_file)
  let s:jshintrc = readfile(s:jshintrc_file)
else
  let s:jshintrc = []
end


" WideMsg() prints [long] message up to (&columns-1) length
" guaranteed without "Press Enter" prompt.
if !exists("*s:WideMsg")
    function s:WideMsg(msg)
        let x=&ruler | let y=&showcmd
        set noruler noshowcmd
        redraw
        echo a:msg
        let &ruler=x | let &showcmd=y
    endfun
endif


function! s:JSHintClear()
  " Delete previous matches
  let s:matches = getmatches()
  for s:matchId in s:matches
    if s:matchId['group'] == 'JSHintError'
        call matchdelete(s:matchId['id'])
    endif
  endfor
  let b:matched = []
  let b:matchedlines = {}
  let b:cleared = 1
endfunction

function! s:JSHint()
  highlight link JSHintError SpellBad

  if exists("b:cleared")
      if b:cleared == 0
          call s:JSHintClear()
      endif
      let b:cleared = 1
  endif

  let b:matched = []
  let b:matchedlines = {}

  " Detect range
  if a:firstline == a:lastline
    let b:firstline = 1
    let b:lastline = '$'
  else 
    let b:firstline = a:firstline
    let b:lastline = a:lastline
  endif


  let b:jshint_output = system(s:cmd, join(s:jshintrc + getline(b:firstline, b:lastline), "\n") . "\n")
  if v:shell_error
     echoerr 'could not invoke JSHint!'
  end

  for error in split(b:jshint_output, "\n")
    " Match {line}:{char}:{message}
    let b:parts = matchlist(error, "\\(\\d\\+\\):\\(\\d\\+\\):\\(.*\\)")
    if !empty(b:parts)
      let l:line = b:parts[1] + (b:firstline - 1 - len(s:jshintrc)) " Get line relative to selection

        " Store the error for an error under the cursor
      let s:matchDict = {}
      let s:matchDict['lineNum'] = l:line
      let s:matchDict['message'] = b:parts[3]
      let b:matchedlines[l:line] = s:matchDict
      if g:JSHintHighlightErrorLine == 1
          let s:mID = matchadd('JSHintError', '\%' . l:line . 'l\S.*\(\S\|$\)')
      endif
      " Add line to match list
      call add(b:matched, s:matchDict)
    endif
  endfor
  let b:cleared = 0
endfunction

let b:showing_message = 0

if !exists("*s:GetJSHintMessage")
    function s:GetJSHintMessage()
        let s:cursorPos = getpos(".")

        " Bail if RunJSHint hasn't been called yet
        if !exists('b:matchedlines')
            return
        endif

        if has_key(b:matchedlines, s:cursorPos[1])
            let s:jshintMatch = get(b:matchedlines, s:cursorPos[1])
            call s:WideMsg(s:jshintMatch['message'])
            let b:showing_message = 1
            return
        endif

        if b:showing_message == 1
            echo
            let b:showing_message = 0
        endif
    endfunction
endif

