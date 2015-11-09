# glen's dotfiles
A collection of my dotfiles with an included deploy script to completely replace (with backups of course) all vim, zsh, tmux configurations.
I recommend that you do not blindly run the script and instead pick out the bits and pieces that you find useful.
Especially because the gitconfig file contains references to my own username, email, and name. Everything else should be user-agnostic.

I (think) it depends on solarized colorscheme and powerline fonts in your terminal or everything will look like shit.

TODO:

* Vundle

* Make environment/zsh/bashrc/profile all consistent
* multiple tmux sessions, selector (windows)
* use windows as different workspaces, sessions as different projects

* remove dependencies on oh my zsh
* fix neocomplcache and nerdtree and ctrlp
* add in .profile .bash_profile and .zsh_profile
* get better buffer navigator
* learn how to use fugitive
* make a new alias for easycd to go in reverse order
  * add sshconfig in maybe??? (definitely insecure)
* make deploy script fail unless you are me! (i suggest people don't run it naked)
  * or ask questions and make a better spf13
* folding and shit
* move buffers around (ctrl+p for buffers or something)
* SURROUND

Some plugins to add:
* vim-view maybe
http://vimcasts.org/episodes/aligning-text-with-tabular-vim/
vim-csv
