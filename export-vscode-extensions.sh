#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

code --list-extensions > "$SCRIPTPATH/vscode-extensions.list"
