#! /bin/bash

cd FWFramework/Classes/include
rm -rf FWFramework
mkdir FWFramework
cd FWFramework

ln -s ../../FWFramework/Kernel/*.h ./
ln -s ../../FWFramework/Service/*.h ./
ln -s ../../FWFramework/Toolkit/*.h ./

