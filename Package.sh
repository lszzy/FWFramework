#! /bin/bash

cd Sources/include
rm -rf FWObjC
mkdir FWObjC
cd FWObjC

ln -s ../../FWObjC/Kernel/*.h ./
ln -s ../../FWObjC/Toolkit/*.h ./
ln -s ../../FWObjC/Service/Basic/*.h ./
ln -s ../../FWObjC/Service/Coding/*.h ./
ln -s ../../FWObjC/Module/App/*.h ./
ln -s ../../FWObjC/Module/Model/*.h ./