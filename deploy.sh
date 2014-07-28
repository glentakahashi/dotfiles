#!/bin/sh

#remove and backup old symlinks if they exist
mv ~/.tmux.conf ~/.tmux.conf.bak
mv ~/.tmux.reset.conf ~/.tmux.reset.conf.bak
mv ~/.tmux.colors.conf ~/.tmux.colors.conf.bak
mv ~/.zshrc ~/.zshrc.bak
mv ~/.vimrc.local ~/.vimrc.local.bak
mv ~/.dircolors ~/.dircolors.bak

#make the new symlinks
ln -s projects/dotfiles/tmux.conf ~/.tmux.conf
ln -s projects/dotfiles/tmux.reset.conf ~/.tmux.reset.conf
ln -s projects/dotfiles/tmux-colors-solarized/tmuxcolors-256.conf ~/.tmux.colors.conf
ln -s projects/dotfiles/vimrc ~/.vimrc.local
ln -s projects/dotfiles/zshrc ~/.zshrc
ln -s projects/dotfiles/dircolors-solarized/dircolors.ansi-dark ~/.dircolors
