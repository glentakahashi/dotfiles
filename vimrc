set nocompatible
scriptencoding utf-8

let mapleader = ','
set timeoutlen=1000 ttimeoutlen=0

"easymotion shit
map <Leader> <Plug>(easymotion-prefix)
let g:EasyMotion_smartcase = 1
nmap s <Plug>(easymotion-s)

"allow buffers to be moved off of if they have changes
set hidden

"easily close buffer without closing window
map <leader>d :Bclose<CR>

"Pathogen stuff
execute pathogen#infect()
syntax on
filetype plugin indent on

set shortmess+=filmnrxoOtT          " Abbrev. of messages (avoids 'hit enter')
set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
set virtualedit=onemore             " Allow for cursor beyond last character
set history=1000                    " Store a ton of history (default is 20)
"TODO: actually utilize this
set spell                           " Spell checking on

set backup                  " Backups are nice ...
if has('persistent_undo')
  set undofile                " So is persistent undo ...
  set undolevels=1000         " Maximum number of changes that can be undone
  set undoreload=10000        " Maximum number lines to save for undo on a buffer reload
endif


if &term == 'xterm' || &term == 'screen'
  set t_Co=256            " Enable 256 colors to stop the CSApprox warning and make xterm vim shine
endif
color solarized                 " Load a colorscheme
set background=dark

set tabpagemax=15               " Only show 15 tabs
set showmode                    " Display the current mode
set cursorline                  " Highlight current line

if has('statusline')
  set laststatus=2

  " Broken down into easily includeable segments
  set statusline=%<%f\                     " Filename
  set statusline+=%w%h%m%r                 " Options
  set statusline+=%{fugitive#statusline()} " Git Hotness
  set statusline+=\ [%{&ff}/%Y]            " Filetype
  set statusline+=\ [%{getcwd()}]          " Current dir
  set statusline+=%=%-14.(%l,%c%V%)\ %p%%  " Right aligned file nav info

  let g:airline_theme='powerlineish'       " airline users use the powerline theme
  let g:airline_powerline_fonts=1          " and the powerline fonts
endif

" indent_guides {
let g:indent_guides_auto_colors = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1
let g:indent_guides_enable_on_vim_startup = 1
" }

" Initialize directories {
function! InitializeDirectories()
  let parent = $HOME
  let prefix = 'vim'
  let dir_list = {
        \ 'backup': 'backupdir',
        \ 'views': 'viewdir',
        \ 'swap': 'directory' }

  if has('persistent_undo')
    let dir_list['undo'] = 'undodir'
  endif

  " To specify a different directory in which to place the vimbackup,
  " vimviews, vimundo, and vimswap files/directories, add the following to
  " your .vimrc.local file:
  "   let g:spf13_consolidated_directory = <full path to desired directory>
  "   eg: let g:spf13_consolidated_directory = $HOME . '/.vim/'
  if exists('g:spf13_consolidated_directory')
    let common_dir = g:spf13_consolidated_directory . prefix
  else
    let common_dir = parent . '/.' . prefix
  endif

  for [dirname, settingname] in items(dir_list)
    let directory = common_dir . dirname . '/'
    if exists("*mkdir")
      if !isdirectory(directory)
        call mkdir(directory)
      endif
    endif
    if !isdirectory(directory)
      echo "Warning: Unable to create backup directory: " . directory
      echo "Try: mkdir -p " . directory
    else
      let directory = substitute(directory, " ", "\\\\ ", "g")
      exec "set " . settingname . "=" . directory
    endif
  endfor
endfunction
" }

"Search settings
set incsearch                   " Find as you type search
set hlsearch                    " Highlight search terms
"clear search highlighting
nmap <silent> <leader>/ :noh<CR>

set backspace=indent,eol,start  " Backspace for dummies
set linespace=0                 " No extra spaces between rows
set nu                          " Line numbers on
set showmatch                   " Show matching brackets/parenthesis
set ignorecase                  " Case insensitive search
set smartcase                   " Case sensitive when uc present
set scrolljump=5                " Lines to scroll when cursor leaves screen
set scrolloff=3                 " Minimum lines to keep above and below cursor
set wildmenu                    " Show list instead of just completing
set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part, then all.
set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

set nowrap                      " Don't wrap long lines
set autoindent                  " Indent at the same level of the previous line
"todo, make this dependent on file
set shiftwidth=2                " Use indents of 2 spaces
set expandtab                   " Tabs are spaces, not tabs
set tabstop=2                   " An indentation every four columns
set softtabstop=2               " Let backspace delete indent

" Remove trailing whitespaces and ^M chars
autocmd FileType c,cpp,java,go,php,javascript,python,twig,xml,yml autocmd BufWritePre <buffer> call StripTrailingWhitespace()
map <leader>c :call StripTrailingWhitespace()<CR>

"new tab
"map <silent> <C-t>n :tabe<CR>

"sizing using m for maximize n for maximize down
"map <silent> <C-w>m :tabedit %<CR>
map <silent> <C-n> :bn<CR>
map <silent> <C-m> :bp<CR>

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 1

" Show just the filename
let g:airline#extensions#tabline#fnamemod = ':t'


"create splits using C+w+- and C+w+|
map <silent> <C-w>- :sp<CR>
map <silent> <C-w>\| :vsp<CR>

"TODO: make into buffermove
"Move tabs using Ctrl + h or Ctrl + l
"map <silent> <C-w>h :execute "tabmove" tabpagenr() - 2 <CR>
"map <silent> <C-w>l :execute "tabmove" tabpagenr() <CR>

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk

" Move windows using shift + h or shift + l
map H gT
map L gt

" Yank from the cursor to the end of the line, to be consistent with C and D.
nnoremap Y y$

" Code folding options
nmap <leader>f0 :set foldlevel=0<CR>
nmap <leader>f1 :set foldlevel=1<CR>
nmap <leader>f2 :set foldlevel=2<CR>
nmap <leader>f3 :set foldlevel=3<CR>
nmap <leader>f4 :set foldlevel=4<CR>
nmap <leader>f5 :set foldlevel=5<CR>
nmap <leader>f6 :set foldlevel=6<CR>
nmap <leader>f7 :set foldlevel=7<CR>
nmap <leader>f8 :set foldlevel=8<CR>
nmap <leader>f9 :set foldlevel=9<CR>

" Visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" Fugitive {
nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Gcommit<CR>
nnoremap <silent> <leader>gb :Gblame<CR>
nnoremap <silent> <leader>gl :Glog<CR>
nnoremap <silent> <leader>gp :Git push<CR>
nnoremap <silent> <leader>gw :Gwrite<CR>:GitGutter<CR>
nnoremap <silent> <leader>gg :GitGutterToggle<CR>
"}

" NerdTree {
map <C-e> :NERDTreeToggle<CR>:NERDTreeMirror<CR>
map <leader>e :NERDTreeFind<CR>
nmap <leader>nt :NERDTreeFind<CR>

let NERDTreeShowBookmarks=1
let NERDTreeIgnore=['\.pyc', '\~$', '\.swo$', '\.swp$', '\.git', '\.hg', '\.svn', '\.bzr']
let NERDTreeChDirMode=0
let NERDTreeQuitOnOpen=1
let NERDTreeShowHidden=1
let NERDTreeKeepTreeInNewTab=1
let g:nerdtree_tabs_open_on_gui_startup=0
" }

"fix typos with e/w/q/a
if has("user_commands")
  command! -bang -nargs=* -complete=file E e<bang> <args>
  command! -bang -nargs=* -complete=file W w<bang> <args>
  command! -bang -nargs=* -complete=file Wq wq<bang> <args>
  command! -bang -nargs=* -complete=file WQ wq<bang> <args>
  command! -bang Wa wa<bang>
  command! -bang WA wa<bang>
  command! -bang Q q<bang>
  command! -bang QA qa<bang>
  command! -bang Qa qa<bang>
endif

"fix SignColumn for vim-gitgutter
highlight clear SignColumn

" Strip whitespace {
function! StripTrailingWhitespace()
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " do the business:
  %s/\s\+$//e
  " clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction
" }

"Map leadery/p to use system clipboard
map <leader>y "+y
map <leader>p "+p

" Toggle paste mode via Ctrl + Shift + P
set pastetoggle=<F12>
map <leader>. :set paste!<CR>

"bind kj to Esc in insert or select mode
inoremap kj <Esc>
"vnoremap kj <Esc>

"key bindings for replace line and replace word
noremap rw vep
noremap ry Vp

" Easier horizontal scrolling
map zl zL
map zh zH

" easy replace under word
nnoremap <leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>

" Resizing windows
map <silent> <C-w>k :res +5<CR>
map <silent> <C-w>j :res -5<CR>
map <silent> <C-w>h :vertical resize -5<CR>
map <silent> <C-w>l :vertical resize +5<CR>

"create the .vimbak .vimswap .vimhist directories
call InitializeDirectories()
