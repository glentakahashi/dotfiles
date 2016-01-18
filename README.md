# glen's dotfiles
A collection of my dotfiles with an included deploy script to completely replace (with backups of course) all vim, zsh, tmux configurations.
I recommend that you do not blindly run the script and instead pick out the bits and pieces that you find useful.
Especially because the gitconfig file contains references to my own username, email, and name. Everything else should be user-agnostic.

I (think) it depends on solarized colorscheme and powerline fonts in your terminal or everything will look like shit.

TODO:

* Make environment/zsh/bashrc/profile all consistent
* multiple tmux sessions, selector (windows)
* use windows as different workspaces, sessions as different projects

* remove dependencies on oh my zsh
* add in .profile .bash_profile and .zsh_profile
* get better buffer navigator
* learn how to use fugitive
* add sshconfig in maybe??? (definitely insecure)
* make deploy script fail unless you are me! (i suggest people don't run it naked)
  * or ask questions and make a better spf13
* folding and shit
* move buffers around (ctrl+p for buffers or something)
* SURROUND
* Split vimrc into mutliple files based on plugin they're for?

Some plugins to add:
* vim-view maybe
http://vimcasts.org/episodes/aligning-text-with-tabular-vim/
vim-csv
https://github.com/junegunn/vim-easy-align
https://github.com/junegunn/vim-peekaboo
https://github.com/junegunn/vim-fnr
https://github.com/junegunn/mvmv
#add gem scripts
seoul256.vim 

make sure you install vim with --with-lua
brew install vim --with-lua


## vimplug

vim-oblique overrides the following keys by default:

| Default Key | `<Plug>` map           | Description                                      |
| ----------- | -------------------- | ------------------------------------------------ |
| `/`         | `<Plug>(Oblique-/)`  | Forward search                                   |
| `?`         | `<Plug>(Oblique-?)`  | Backward search                                  |
| `z/`        | `<Plug>(Oblique-F/)` | Forward fuzzy-search                             |
| `z?`        | `<Plug>(Oblique-F?)` | Backward fuzzy-search                            |
| `n`         | `<Plug>(Oblique-n)`  | Repeat the last search                           |
| `N`         | `<Plug>(Oblique-N)`  | Repeat the last search in the opposite direction |
| `*`         | `<Plug>(Oblique-*)`  | Forward star-search (in normal and visual mode)  |
| `#`         | `<Plug>(Oblique-#)`  | Backward star-search (in normal and visual mode) |
| `g*`        | `<Plug>(Oblique-g*)` | Forward star-search (no word boundary match)     |
| `g#`        | `<Plug>(Oblique-g#)` | Backward star-search (no word boundary match)    |
