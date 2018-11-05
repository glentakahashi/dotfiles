# glen's dotfiles
A collection of my dotfiles with an included deploy script to completely replace (with backups of course) all vim, zsh, tmux configurations.
I recommend that you do not blindly run the script and instead pick out the bits and pieces that you find useful.
Especially because the gitconfig file contains references to my own username, email, and name. Everything else should be user-agnostic.

I (think) it depends on solarized colorscheme and powerline fonts in your terminal or everything will look like shit.

TODO:

* Make environment/zsh/bashrc/profile all consistent
* multiple tmux sessions, selector (windows)
* use windows as different workspaces, sessions as different projects
* add fugitive, syntastic to numbers_exclude
* fix weird loclist issues with syntastic
* add check for bufferclose to safely close fugitive windows and oher windows

* switch newline prompt to be the right and left unicode/emoji arrows, colorize for vim mode
* colorize username + computer in prompt

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
https://github.com/ggVGc/fzf_browser
https://stackoverflow.com/questions/26554713/how-to-truncate-working-directory-in-prompt-to-show-first-and-last-folder
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
#add gem scripts
seoul256.vim 

git-flow

https://github.com/haya14busa/vim-easyoperator-line
https://github.com/takac/vim-hardtime
https://github.com/justinmk/vim-sneak

antigen - zsh plugin manager
or better yet, a simple script that you specify a repo a branch and a relatilve file path and it will clone and source the file
git@github.com:atweiden/fzf-extras.git

make sure you install vim with --with-lua
brew install vim --with-lua

youcompleteme, clang, xbuild(mono), etc.
dependencies: go, rust, mono, clang, cmake
go,rust,mono,cmake are from homebre
install clang by typing clang and using the UI
https://github.com/Valloric/YouCompleteMe

fish is a pretty awesome shell
learn from fish

# Dependencies

* All
  * Vim with lua, clipboard
  * fzf
  * git
  * ag
* Optional
  * mono
  * go
  * typescript
  * clang
  * rust
* Mac
  * homebrew
  * homebrew-coreutils

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

## fzf

| Token    | Match type           | Description                      |
| -------- | -------------------- | -------------------------------- |
| `sbtrkt` | fuzzy-match          | Items that match `sbtrkt`        |
| `^music` | prefix-exact-match   | Items that start with `music`    |
| `.mp3$`  | suffix-exact-match   | Items that end with `.mp3`       |
| `'wild`  | exact-match (quoted) | Items that include `wild`        |
| `!rmx`   | inverse-fuzzy-match  | Items that do not match `rmx`    |
| `!'fire` | inverse-exact-match  | Items that do not include `fire` |
