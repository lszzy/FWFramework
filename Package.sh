#! /bin/bash

cd Sources/include
rm -rf FWObjC
mkdir FWObjC
cd FWObjC

ln -s ../../FWObjC/*.h ./
ln -s ../../FWObjC/Service/Network/*.h ./
ln -s ../../FWObjC/Service/Request/*.h ./
ln -s ../../FWObjC/Service/Media/*.h ./
ln -s ../../FWObjC/Service/Database/*.h ./
ln -s ../../FWObjC/Module/View/*.h ./
ln -s ../../FWObjC/Plugin/Picker/*.h ./
ln -s ../../FWObjC/Plugin/Preview/*.h ./
