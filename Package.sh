#! /bin/bash

cd Sources/include
rm -rf FWObjC
mkdir FWObjC
cd FWObjC

ln -s ../../FWObjC/Kernel/*.h ./
ln -s ../../FWObjC/Service/Basic/*.h ./
