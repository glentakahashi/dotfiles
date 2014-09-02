map <C-H> :execute "tabmove" tabpagenr() - 2 <CR>
map <C-L> :execute "tabmove" tabpagenr() <CR>
"Map leadery/p to use system clipboard
map <leader>y "+y
map <leader>p "+p
filetype indent on

"this will take getting used to
inoremap kj <Esc>
"vnoremap kj <Esc>
"noremap pp p
"nmap pw viwpp
"nmap py Vpp
