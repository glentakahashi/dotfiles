#!/bin/sh

#get the directly of where this script is run, and consequently where the files are located
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

#git depends on being in directory, so cd to directory first
cd $SCRIPTPATH
#init and update if we haven't already
echo Updating submodules...
git submodule init
git submodule foreach git pull origin master
