#! /bin/bash

cd Sources/include
rm -rf FWObjC
mkdir FWObjC
cd FWObjC

ln -s ../../FWObjC/*.h ./
ln -s ../../FWObjC/Service/Network/*.h ./
ln -s ../../FWObjC/Service/Media/*.h ./
ln -s ../../FWObjC/Service/Database/*.h ./
