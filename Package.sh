#! /bin/bash

cd Sources/include
rm -rf FWObjC
mkdir FWObjC
cd FWObjC

ln -s ../../FWObjC/Kernel/*.h ./
ln -s ../../FWObjC/Toolkit/*.h ./
ln -s ../../FWObjC/Service/Basic/*.h ./
ln -s ../../FWObjC/Service/Coding/*.h ./
ln -s ../../FWObjC/Service/Cache/*.h ./
ln -s ../../FWObjC/Service/Network/*.h ./
ln -s ../../FWObjC/Service/Request/*.h ./
ln -s ../../FWObjC/Service/Media/*.h ./
ln -s ../../FWObjC/Service/Database/*.h ./
ln -s ../../FWObjC/Module/App/*.h ./
ln -s ../../FWObjC/Module/Model/*.h ./
ln -s ../../FWObjC/Module/View/*.h ./
ln -s ../../FWObjC/Plugin/View/*.h ./
ln -s ../../FWObjC/Plugin/Toast/*.h ./
ln -s ../../FWObjC/Plugin/Refresh/*.h ./
ln -s ../../FWObjC/Plugin/Empty/*.h ./
ln -s ../../FWObjC/Plugin/Image/*.h ./
