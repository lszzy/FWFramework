#! /bin/bash

cd FWFramework/Classes/Objc/include
rm -rf FWFramework
mkdir FWFramework
cd FWFramework

ln -s ../../Kernel/*.h ./
ln -s ../../Service/*.h ./
ln -s ../../Toolkit/*.h ./

