#! /bin/bash

PWD_PATH=`pwd`

rm -rf ~/Library/Developer/Xcode/UserData/CodeSnippets.backup
mv ~/Library/Developer/Xcode/UserData/CodeSnippets ~/Library/Developer/Xcode/UserData/CodeSnippets.backup
cp -rf ${PWD_PATH}/CodeSnippets ~/Library/Developer/Xcode/UserData/CodeSnippets

open ~/Library/Developer/Xcode/UserData/
