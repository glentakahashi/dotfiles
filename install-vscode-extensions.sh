#!/bin/bash

#get the directly of where this script is run, and consequently where the files are located
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

while read EX; do
    code --install-extension "$EX"
done <"$SCRIPTPATH/vscode-extensions.list"
