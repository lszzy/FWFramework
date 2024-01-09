#! /bin/bash

framework_name=FWFramework

mv docs/CNAME ./ 
rm -rf docs
mkdir docs
mv CNAME docs/
mkdir "docs/$framework_name"

umbrella_name="$framework_name.h"
lib_path="docs/$framework_name/"
sdk_path=$(xcrun --show-sdk-path --sdk iphonesimulator)
find "Sources/FWObjC" -type f ! -regex '*.h' -name '*.h' \
    -exec cp {} $lib_path \;

sourcekitten doc -- -project _Pods.xcodeproj -target $framework_name > "$lib_path/swift.json"
sourcekitten doc --objc "$lib_path/$umbrella_name" -- -x objective-c -isysroot $sdk_path -I $lib_path -fobjc-arc -fmodules > "$lib_path/objc.json"
jazzy --include-spi-declarations --sourcekitten-sourcefile "$lib_path/swift.json","$lib_path/objc.json"

rm -rf $lib_path
rm -rf Example/build/
cp *.md docs/
