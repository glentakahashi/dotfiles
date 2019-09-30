#!/bin/bash

EXTENSIONS=$(code --list-extensions)

for EX in ${EXTENSIONS[@]}; do
    code --uninstall-extension "$EX"
done
