"   *************************************
"   * Variables
"   *************************************

" Default Shell
set shell=bash                  "default login shell is set to bash

" Color Profiles
colorscheme solarized
syntax enable
set background=dark

set nojoinspaces                " no more implicit whitespace creation
set ruler                       " tells you what line you are on
set ts=4                        " tabs are set equivalent to 4 spaces
set ai
set nocompatible                " get rid of strict vi compatibility
set ignorecase                  " search without regards to case
set fileformats=unix,dos,mac    " open files from mac/dos
set nohlsearch                  " highlighting turned off when searching
set showmatch                   " jumping between matches
set binary noeol                " no eol attached to end, always unix format
set nu                          " line numbering on
set incsearch                   " incremental searching
set cindent
set nopaste
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent                  " autoindent on
set smartindent
set laststatus=2
set mousemodel=popup
set hidden
set noerrorbells                " no more error bells
set noic
set backspace=2                 " fix backspacing in insert mode

let mapleader = ","

filetype on
filetype plugin on
filetype indent on

" Mapping for ctags
nmap <silent><Leader>B <ESC>/end<CR>=%:noh<CR>
nmap <silent> <M-S-Left> <ESC>:bp<CR>
nmap <Leader>U <ESC>:TlistUpdate<CR>
nmap <Leader>M <ESC>:wa<CR>:make!<CR>
nmap <Leader>D <ESC>:w<CR>:diffthis<CR>
nmap <Leader>d <ESC>:w<CR>:diffoff<CR>
nmap <silent><Leader>q <ESC>:copen<CR>
nmap <silent><Leader>n <ESC>:cn<CR>
nmap <silent><Leader>; <ESC>d/;/e<CR>:noh<CR>
nmap <Leader><Leader>s <ESC>:cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <Leader><Leader>g <ESC>:cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <Leader><Leader>d <ESC>:cs find d <C-R>=expand("<cword>")<CR><CR>
nmap <Leader><Leader>c <ESC>:cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <Leader><Leader>t <ESC>:cs find t 
nmap <Leader><Leader>e <ESC>:cs find e 
nmap <Leader><Leader>f <ESC>:cs find f <C-R>=expand("<cword>")<CR><CR>
nmap <Leader><Leader>i <ESC>:cs find i <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>P <ESC>:Pydoc <C-R>=expand("<cword>")<CR>
map <C-_> :cstag <C-R>=expand("<cword>")<CR><CR>
noremap <f11> <esc>:syntax sync fromstart<cr>
inoremap <f11> <esc>:syntax sync fromstart<cr>a

" Similar to bash style ctrl+e and ctrl+a for start and end of line. ctrl+d is
" mapped to dd
inoremap <c-d> <esc>ddi
inoremap <c-e> <esc>A
inoremap <c-a> <esc>I
" inoremap <c-s> <esc>:w
" inoremap <c-q> <esc>:wq
nnoremap    <leader>w <c-w>w
" Pressing <leader>+" sets quotations around the word you are on.
nnoremap    <leader>" viw<esc>a"<esc>hbi"<esc>lel

"Remove normal mappings for arrow movement
nnoremap    <up>    <nop>
nnoremap    <down>  <nop>
nnoremap    <left>  <nop>
nnoremap    <right> <nop>

" Open up vimrc file with <leader>ev and source with <leader>sv
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

set statusline=%<%f%=\ [%1*%M%*%n%R]\ y\ %-19(%3l,%02c%03V%)

nmap <Leader>S <ESC>:setlocal spell spelllang=en_us<CR>

set tags=tags;/Users/jjangsangy

set whichwrap+=<,>,h,l

autocmd FileType ruby set path=./**,**
setl path=./**,**

nmap <F12> <Esc>:wa<CR>:mksession!<CR>:qa<CR>

if has("cscope")
  set csprg=/usr/local/bin/cscope
  set csto=0
  set cst
  set nocsverb
  if filereadable("cscope.out")
    cs add cscope.out
  elseif $CSCOPE_DB != ""
    cs add $CSCOPE_DB
  endif
  set csverb
endif


autocmd BufRead *.rl  setfiletype=ragel
autocmd BufRead *.asm  setfiletype=earing
autocmd BufRead *.factor  setfiletype=factor

runtime! ftplugin/man.vim
set grepprg=/usr/local/bin/ack


let g:pydiction_location = '/Users/jjangsangy/.vim/ftplugin/complete-dict'

call pathogen#infect()