#! /bin/bash

PWD_PATH=`pwd`

rm -rf ~/Library/Developer/Xcode/Templates.backup
mv ~/Library/Developer/Xcode/Templates ~/Library/Developer/Xcode/Templates.backup
cp -rf ${PWD_PATH}/Templates ~/Library/Developer/Xcode/Templates

open ~/Library/Developer/Xcode/
