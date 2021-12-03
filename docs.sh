#! /bin/bash

rm -rf docs
mkdir docs

sourcekitten doc -- -workspace Example/Example.xcworkspace -scheme FWFramework > docs/FWSwift.json
sourcekitten doc --objc FWFramework/Classes/Kernel/FWFramework.h -- -x objective-c -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I $(pwd) -fmodules > docs/FWKernel.json
sourcekitten doc --objc FWFramework/Classes/Service/FWNotification.h -- -x objective-c -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I $(pwd) -fmodules > docs/FWService.json
sourcekitten doc --objc FWFramework/Classes/Toolkit/FWToolkit.h -- -x objective-c -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I $(pwd) -fmodules > docs/FWToolkit.json
jazzy --sourcekitten-sourcefile docs/FWKernel.json,docs/FWService.json,docs/FWToolkit.json,docs/FWSwift.json

rm -f docs/FWSwift.json
rm -f docs/FWKernel.json
rm -f docs/FWService.json
rm -f docs/FWToolkit.json

ln -s README.md docs/README.md
ln -s README_CN.md docs/README_CN.md
ln -s CHANGELOG.md docs/CHANGELOG.md
ln -s CHANGELOG_CN.md docs/CHANGELOG_CN.md

