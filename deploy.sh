#!/bin/bash

#get the directly of where this script is run, and consequently where the files are located
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SYSTEM=${OSTYPE//[0-9.]/}

#warn if they already have one of the .bak files that exists
if [[  -e ~/.tmux.conf.bak || -e ~/.tmux.reset.conf.bak \
    || -e ~/.tmux.colors.conf.bak || -e ~/.tmux.system.conf.bak \
    || -e ~/.zshrc.bak || -e ~/.vimrc.bak \
    || -e ~/.dircolors.bak || -e ~/.vim.bak
    || -e ~/.zsh.bak || -e ~/.gitconfig.bak ]]; then
    echo "Warning! one or more *.bak files exist in your home directory that may get overwritten!"
    read -p "Continue? [y/n]" yn
    while true; do
        case $yn in
            [Yy]* )
                break
                ;;
            [Nn]* )
                exit
                ;;
            * )
                read -p "Please answer yes or no. [y/n]" yn
                ;;
        esac
    done
fi

#git depends on being in directory, so cd to directory first
cd $SCRIPTPATH

function backupIfNotSymlink() {
    if [[ -L $1 ]]; then
        rm -v "$1"
    elif [[ -e $1 ]]; then
        mv -v -f "$1" "$1.bak"
    fi
}

#remove symlinks if they exist or backup file
backupIfNotSymlink ~/.tmux.conf
backupIfNotSymlink ~/.tmux.reset.conf
backupIfNotSymlink ~/.tmux.colors.conf
backupIfNotSymlink ~/.tmux.system.conf
backupIfNotSymlink ~/.zshrc
backupIfNotSymlink ~/.zshrc.system
backupIfNotSymlink ~/.zshrc.fzf
backupIfNotSymlink ~/.vimrc
backupIfNotSymlink ~/.vimplug
backupIfNotSymlink ~/.dircolors
backupIfNotSymlink ~/.gitconfig
rm -rf ~/.vim.bak
backupIfNotSymlink ~/.vim
backupIfNotSymlink ~/.zsh
backupIfNotSymlink ~/Library/Application\ Support/Code/User/settings.json
backupIfNotSymlink ~/.template.html

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/seebi/tmux-colors-solarized ~/.tmux-colors-solarized
git clone https://github.com/seebi/dircolors-solarized ~/.dircolors-solarized
git clone https://github.com/glentakahashi/oh-my-zsh.git ~/.oh-my-zsh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo ~/.z.sh https://raw.githubusercontent.com/rupa/z/master/z.sh

#make the new symlinks
ln -v -s $SCRIPTPATH/tmux.conf ~/.tmux.conf
ln -v -s $SCRIPTPATH/tmux.reset.conf ~/.tmux.reset.conf
ln -v -s ~/.tmux-colors-solarized/tmuxcolors-256.conf ~/.tmux.colors.conf
ln -v -s $SCRIPTPATH/vimrc ~/.vimrc
ln -v -s $SCRIPTPATH/vimplug ~/.vimplug
ln -v -s $SCRIPTPATH/zshrc ~/.zshrc
ln -v -s $SCRIPTPATH/zshrc.fzf ~/.zshrc.fzf
ln -v -s ~/.dircolors-solarized/dircolors.ansi-dark ~/.dircolors
ln -v -s $SCRIPTPATH/template.html ~/.template.html
#ln -v -s $SCRIPTPATH/gitconfig ~/.gitconfig
#COPY GITCONFIG BECAUSE IF ITS BROKEN ITS ANNOYING TO MERGE
cp -v $SCRIPTPATH/gitconfig ~/.gitconfig

if [[ $SYSTEM == "darwin" ]]; then
    ln -v -s $SCRIPTPATH/vscode.json ~/Library/Application\ Support/Code/User/settings.json
fi

#these two files depend upon system type
ln -s $SCRIPTPATH/$SYSTEM/tmux.system.conf ~/.tmux.system.conf
ln -s $SCRIPTPATH/$SYSTEM/zshrc.system ~/.zshrc.system

#create the local changes files if they don't exist
touch ~/.tmux.local.conf
touch ~/.zshrc.local
touch ~/.vimrc.local

vim +PlugClean +PlugUpdate +qall

python ~/.vim/plugged/YouCompleteMe/install.py
